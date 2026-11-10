import sys
import unittest
from pathlib import Path
from copy import deepcopy
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from report_store import merge_profile, GenerationConflict

def profile(pid='TEST', **kwargs):
    return dict(patient_id=pid, sessions=[], rom_history=[], levels={}, **kwargs)

class ReportStoreTests(unittest.TestCase):
    def test_reset_endpoint_is_idempotent_and_removes_sessions(self):
        import mongodb_service as service
        class Collection:
            def __init__(self, rows): self.rows = rows
            def find_one(self, query, *args):
                return next((deepcopy(r) for r in self.rows if all(r.get(k)==v for k,v in query.items())), None)
            def update_one(self, query, update, **kwargs):
                for row in self.rows:
                    if all(row.get(k)==v for k,v in query.items()):
                        row.update(deepcopy(update['$set'])); return
                self.rows.append(dict(query, **deepcopy(update['$set'])))
            def delete_many(self, query):
                self.rows[:] = [r for r in self.rows if not all(r.get(k)==v for k,v in query.items())]
        db = {'patient_profiles': Collection([dict(_id='TEST', **profile())]),
              'exercise_sessions': Collection([dict(patient_id='TEST'),dict(patient_id='OTHER')])}
        handler = object.__new__(service.MongoBridgeRequestHandler)
        handler.path = '/api/patients/TEST/reset'
        handler._extract_mongo_headers = lambda: (None,None)
        handler._read_json_body = lambda: dict(expected_generation=0,reset_token='unique')
        replies=[]
        handler._send_json=lambda code,data: replies.append((code,data))
        original=service.get_mongo_database
        service.get_mongo_database=lambda *args: db
        try:
            handler._handle_write()
            handler._handle_write()
            self.assertEqual([r[0] for r in replies],[200,200])
            self.assertEqual(db['patient_profiles'].rows[0]['generation'],1)
            self.assertEqual(db['exercise_sessions'].rows,[dict(patient_id='OTHER')])
            handler._read_json_body=lambda: dict(expected_generation=0,reset_token='stale')
            handler._handle_write()
            self.assertEqual(replies[-1][0],409)
        finally: service.get_mongo_database=original

    def test_union_keeps_offline_sessions_and_filters_other_patients(self):
        a, b = profile(), profile()
        a['sessions'] = [dict(patient_id='TEST', session_id='a')]
        b['sessions'] = [dict(patient_id='TEST', session_id='b'), dict(patient_id='OTHER', session_id='c'), dict(session_id='legacy')]
        self.assertEqual({s['session_id'] for s in merge_profile(a,b)['sessions']}, {'a','b'})

    def test_reset_generation_rejects_old_client(self):
        with self.assertRaises(GenerationConflict):
            merge_profile(profile(generation=1), profile())

    def test_daily_calibration_and_legacy_are_separate(self):
        a, b = profile(), profile()
        a['rom_history'] = [dict(date='2026-11-01', source='calibration', rom_angle=80)]
        b['rom_history'] = [dict(date='2026-11-01', source='session', rom_angle=90)]
        result = merge_profile(a,b)
        self.assertEqual(len(result['rom_history']),2)
        self.assertEqual(result['max_rom_angle'],80)

    def test_merge_idempotent_and_does_not_mutate_input(self):
        a = profile()
        before = deepcopy(a)
        merged = merge_profile(a,a)
        self.assertEqual(merge_profile(merged,a),merged)
        self.assertEqual(a,before)

if __name__ == '__main__': unittest.main()
