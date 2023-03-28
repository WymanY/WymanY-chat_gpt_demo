import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// a singleton ConfigManger class,which is used to manage the config of the app
/// when init the app, call [ConfigManager.init] to load the config from the config file
/// then you can use [ConfigManager.instance] to get the config
class ConfigManager {
  static ConfigManager? _instance;
  static ConfigManager get instance {
    if (_instance == null) {
      throw Exception('ConfigManager has not been initialized');
    }
    return _instance!;
  }

  late String apiToken;

  /// init the ConfigManager
  static Future<void> init() async {
    _instance = ConfigManager._();
    await _instance!._init();
  }

  ConfigManager._();

  _init() async {
    // get ApiToken From shared_preferences if it exists else get it from config.yaml
    // when get it from config.yaml, store it in shared_preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localApiToken = prefs.getString('apiToken');

    if (localApiToken != null) {
      apiToken = localApiToken;
      return;
    } else {
      String configString =
          await rootBundle.loadString('lib/config/config.yaml');
      final configMap = loadYaml(configString);
      localApiToken = configMap["ApiToken"];
      if (localApiToken == null) {
        throw Exception('set ApiToken in config.yaml');
      }
      apiToken = localApiToken;
      await prefs.setString('apiToken', apiToken);
      return;
    }
  }
}
