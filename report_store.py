"""Pure profile merge rules. No database/network access on import."""
from copy import deepcopy

class GenerationConflict(ValueError):
    pass

def merge_profile(existing, incoming):
    old, new = deepcopy(existing or {}), deepcopy(incoming)
    pid = str(new.get('patient_id', '')).strip()
    if not pid or (old and old.get('patient_id', pid) != pid):
        raise ValueError('PATIENT_ID_MISMATCH')
    if int(old.get('generation', 0)) != int(new.get('generation', 0)):
        raise GenerationConflict('PROFILE_RESET_ELSEWHERE: reload before retrying')
    result = dict(old if str(old.get('updated_at_utc', '')) > str(new.get('updated_at_utc', '')) else new)
    result['patient_id'] = pid
    result['generation'] = int(old.get('generation', 0))
    sessions = {}
    for row in old.get('sessions', []) + new.get('sessions', []):
        if isinstance(row, dict) and row.get('patient_id') == pid and row.get('session_id'):
            sessions[row['session_id']] = row
    result['sessions'] = sorted(sessions.values(), key=lambda s: s.get('ended_at_utc', s.get('completed_at_utc', '')))
    points = {}
    for row in old.get('rom_history', []) + new.get('rom_history', []):
        if not isinstance(row, dict) or row.get('patient_id', pid) != pid:
            continue
        key = (str(row.get('date', '')), str(row.get('source', 'legacy')))
        if key not in points or float(row.get('rom_angle', 0)) > float(points[key].get('rom_angle', 0)):
            points[key] = row
    result['rom_history'] = sorted(points.values(), key=lambda p: str(p.get('date', '')))
    result['levels'] = {str(i): max(int(old.get('levels', {}).get(str(i), 1)), int(new.get('levels', {}).get(str(i), 1))) for i in range(1, 6)}
    calibrations = [p for p in result['rom_history'] if p.get('source') == 'calibration']
    if calibrations:
        result['max_rom_angle'] = max(calibrations, key=lambda p: str(p.get('updated_at_utc', p.get('date', ''))))['rom_angle']
    return result
