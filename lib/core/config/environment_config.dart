enum Environment { stage, prod }

class AppConfig {
  static Environment environment = Environment.prod;
  static String baseUrl = "https://setu.indevconsultancy.in/api";
  static String appName = "Setu";
  static String signInSubtitle = "COHV Reporting App";
  static void setEnvironment(Environment env) {
    environment = env;
    switch (env) {
      case Environment.stage:
        baseUrl = "https://onehealth-stage.indevconsultancy.in/api";
        appName = "Setu Training";
        signInSubtitle = "COHV Training App";
        break;

      case Environment.prod:
        baseUrl = "https://setu.indevconsultancy.in/api";
        appName = "Setu";
        signInSubtitle = "COHV Reporting App";
        break;
    }
  }

  static bool get isStage => environment == Environment.stage;
  static bool get isProd => environment == Environment.prod;
}
