package fire_duck;

class Connectors {
	static var getClient:Promise<tink.http.Client> = {
		var client:tink.http.Client = new NodeClient();
		var getApiKey:Promise<tink.Chunk> = AppSettings.config.wildDuck.apiKey;
    if(AppSettings.config.firebase.standalone) firebaseInit();
		getApiKey.next(apiKey -> client.augment({
			before: [
				req -> {
					@:privateAccess req.header.fields.push(new HeaderField("x-access-token", apiKey));
					req;
				}
			]
		}));
	};
  static function firebaseInit() {
    FirebaseAdmin.initializeApp({
      credential: firebase_admin.Credential.cert(boisly.AppSettings.config.firebase.svcCfg),
      databaseURL: boisly.AppSettings.config.firebase.databaseURL
    });
  }
	public static var duck:Promise<bp.duck.Proxy> = getClient.next(client -> tink.Web.connect((AppSettings.config.duckApiUrl : bp.duck.proxy.WildDuckProxy), {client: client}));
}
