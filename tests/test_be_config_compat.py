import json, os, tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import mongodb_service as mongo

class ConfigCompatibilityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.cloud = self.root / "cloud_config.json"
        self.legacy = self.root / "mongodb_config.json"
        self.patches = [patch.object(mongo,"CLOUD_CONFIG_PATH",str(self.cloud)), patch.object(mongo,"CONFIG_FILE_PATH",str(self.legacy)), patch.dict(os.environ,{"MONGODB_URI":"mongodb://env","MONGODB_DB":"env_db"})]
        for p in self.patches: p.start()
    def tearDown(self):
        for p in reversed(self.patches): p.stop()
        self.temp.cleanup()
    def test_generic_cloud_does_not_override_environment(self):
        self.cloud.write_text(json.dumps({"enabled":True,"provider":"supabase","url":"example"}))
        self.assertEqual(mongo.load_saved_mongo_config()["mongodb_uri"],"mongodb://env")
    def test_shared_config_fallback_and_legacy_priority(self):
        self.cloud.write_text(json.dumps({"mongodb_uri":"mongodb://shared","database_name":"shared"}),encoding="utf-8-sig")
        self.assertEqual(mongo.load_saved_mongo_config()["database_name"],"shared")
        self.legacy.write_text(json.dumps({"mongodb_uri":"mongodb://existing","database_name":"existing"}))
        self.assertEqual(mongo.load_saved_mongo_config()["database_name"],"existing")
    def test_malformed_cloud_falls_back_and_save_preserves_cloud(self):
        self.cloud.write_text("broken-json")
        mongo.save_mongo_config("mongodb://saved","saved")
        self.assertEqual(mongo.load_saved_mongo_config()["database_name"],"saved")
        self.assertEqual(self.cloud.read_text(),"broken-json")
    def test_server_lifecycle_flags(self):
        self.assertTrue(mongo.MongoBridgeHTTPServer.allow_reuse_address)
        self.assertTrue(mongo.MongoBridgeHTTPServer.daemon_threads)
