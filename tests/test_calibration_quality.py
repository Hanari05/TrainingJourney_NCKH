import sys
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from exercises_logic import ExercisesEvaluator

class Identity:
    def filter(self, value): return value
    def reset(self): pass

class CalibrationTests(unittest.TestCase):
    def setUp(self):
        self.clock=patch('exercises_logic.time.monotonic',return_value=100.0).start()
        self.addCleanup(patch.stopall)
        self.e=ExercisesEvaluator()
        self.e.filter=Identity()
        self.e.check_tracking_status=lambda lm:(lm is not None,'POSITION_OK' if lm else 'TRACKING_LOST')
        self.good=True
        self.e._evaluate_calibration_t_pose=lambda lm:dict(form_valid=self.good,current_rom_value=75,left_rom_value=74,right_rom_value=76,feedback_code='KEEP_POSITION')
        self.e.start_calibration('scapular_retraction',5000)
    def sample(self,t,body=True,stamp=None):
        self.clock.return_value=100+t
        return self.e.process_calibration(object() if body else None,stamp)
    def test_one_bad_sample_then_tracking_loss_never_succeeds(self):
        self.good=False
        self.sample(.1)
        self.assertIsNone(self.sample(5.1,False)[1])
        result=self.sample(20.1,False)[1]
        self.assertFalse(result['success'])
        self.assertEqual(result['valid_elapsed_ms'],0)
    def test_valid_five_seconds_succeeds(self):
        result=None
        for i in range(53):
            _,result=self.sample(i*.1,stamp=i)
            if result: break
        self.assertTrue(result['success'])
        self.assertEqual(result['valid_elapsed_ms'],5000)
        self.assertEqual(result['measurement_kind'],'normalized_t_pose')
    def test_loss_pauses_progress_and_timeout_preserves_prior_calibration(self):
        self.e.calibrated_global_max_rom=82
        for i in range(11): self.sample(i*.1)
        before=self.e.calib_valid_ms
        self.sample(5,False)
        self.sample(5.1)
        self.assertEqual(self.e.calib_valid_ms,before)
        result=self.sample(20.1,False)[1]
        self.assertFalse(result['success'])
        self.assertEqual(self.e.calibrated_global_max_rom,82)
    def test_repeated_callback_cannot_fill_timer(self):
        for i in range(100): self.sample(i*.1,stamp=1)
        self.assertEqual(self.e.calib_sample_count,1)
        self.assertEqual(self.e.calib_valid_ms,0)
    def test_long_gap_not_counted(self):
        self.sample(0)
        self.sample(4)
        self.assertEqual(self.e.calib_valid_ms,0)
    def test_nan_rejected(self):
        self.e._evaluate_calibration_t_pose=lambda lm:dict(form_valid=True,current_rom_value=float('nan'),left_rom_value=75,right_rom_value=75)
        result=None
        for i in range(202):
            _,result=self.sample(i*.1)
            if result: break
        self.assertFalse(result['success'])

if __name__=='__main__': unittest.main()
