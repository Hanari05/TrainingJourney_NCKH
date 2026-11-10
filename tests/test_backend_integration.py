import asyncio
import ast
import importlib.util
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from hand_service import HandService
from exercises_logic import LandmarkPoint

class HandTests(unittest.TestCase):
    def test_raise_lower_and_tracking_loss(self):
        service = HandService()
        points = [LandmarkPoint(.5,.85,0,1) for _ in range(33)]
        self.assertFalse(service.process(points)['active'])
        points[19] = LandmarkPoint(.5,.4,0,1)
        data = service.process(points)
        self.assertTrue(data['active'])
        self.assertTrue(0 <= data['cursor_x'] <= 1 and 0 <= data['cursor_y'] <= 1)
        self.assertFalse(service.process(None)['active'])
        service.reset()
        self.assertIsNone(service.active_side)

class BackendTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        class Closed(Exception): pass
        self.cv = MagicMock()
        ws = types.SimpleNamespace(exceptions=types.SimpleNamespace(ConnectionClosed=Closed,ConnectionClosedOK=Closed))
        spec = importlib.util.spec_from_file_location('merged_backend_test', Path(__file__).resolve().parents[1]/'main.py')
        self.backend = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {'cv2':self.cv,'mediapipe':MagicMock(),'websockets':ws}), patch('atexit.register'), patch('signal.signal'):
            spec.loader.exec_module(self.backend)
    def test_failed_camera_handles_are_released(self):
        bad1,bad2,good = MagicMock(),MagicMock(),MagicMock()
        bad1.isOpened.return_value=False
        bad2.isOpened.return_value=True;bad2.read.return_value=(False,None)
        good.isOpened.return_value=True;good.read.return_value=(True,object())
        self.cv.VideoCapture.side_effect=[bad1,bad2,good]
        with patch.object(self.backend.sys,'platform','win32'):
            self.assertIs(self.backend.open_webcam(),good)
        bad1.release.assert_called_once();bad2.release.assert_called_once();good.release.assert_not_called()
    async def test_critical_timeout_closes_connection(self):
        client=types.SimpleNamespace(send=AsyncMock(side_effect=asyncio.TimeoutError),close=AsyncMock())
        self.backend.app_state['connected_client']=client
        await self.backend.send_to_godot({'type':'exercise_event'})
        self.assertIsNone(self.backend.app_state['connected_client'])
        client.close.assert_awaited_once()
    async def test_disposable_timeout_does_not_drop_connection(self):
        client=types.SimpleNamespace(send=AsyncMock(side_effect=asyncio.TimeoutError),close=AsyncMock())
        self.backend.app_state['connected_client']=client
        await self.backend.send_to_godot({'type':'camera_frame'})
        self.assertIs(self.backend.app_state['connected_client'],client)
        client.close.assert_not_awaited()
    async def test_loss_invalidates_snapshot_and_hand(self):
        self.backend.latest_snapshot=(object(),123)
        self.backend.latest_result=object()
        self.backend.send_to_godot=AsyncMock()
        await self.backend.notify_camera_unavailable()
        self.assertEqual(self.backend.latest_snapshot,(None,0))
        self.assertIsNone(self.backend.latest_result)
        messages=[call.args[0] for call in self.backend.send_to_godot.await_args_list]
        self.assertEqual([m['type'] for m in messages],['hand_control','tracking_status'])
        self.assertFalse(messages[0]['payload']['active'])
        self.assertFalse(messages[1]['payload']['person_detected'])
    def test_shutdown_is_idempotent(self):
        self.backend.stop_mongodb_bridge=MagicMock()
        cap=MagicMock();landmarker=MagicMock()
        self.backend._active_camera=cap;self.backend._active_landmarker=landmarker
        self.backend.cleanup_resources();self.backend.cleanup_resources()
        cap.release.assert_called_once();landmarker.close.assert_called_once()
        self.backend.stop_mongodb_bridge.assert_called_once()
    def test_freshness_and_sample_timestamp_are_preserved(self):
        tree=ast.parse((Path(__file__).resolve().parents[1]/'main.py').read_text(encoding='utf-8-sig'))
        calls=[n for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute) and n.func.attr=='process_calibration']
        self.assertEqual(len(calls),1)
        self.assertEqual(len(calls[0].args),2)

if __name__ == '__main__':unittest.main()
