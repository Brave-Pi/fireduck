package fire_duck;

@:await class Connectors {
	static var getClient:Promise<tink.http.Client> = {
		var client:tink.http.Client = new NodeClient();
		var getApiKey:Promise<tink.Chunk> = AppSettings.config.wildDuck.apiKey;
		if (AppSettings.config.firebase.standalone)
			firebaseInit();
		getApiKey.next(apiKey -> {
			client.augment({
				before: [
					req -> {
						@:privateAccess req.header.fields.push(new HeaderField("x-access-token", apiKey));
						req;
					}
				]
				#if debug
				, after: [
					req -> {
						res -> {
							req.body.all().next(body -> {
								log(req.header);
								log(body);
								res.body.all().next(body -> {
									log(res.header);
									log(body);
									res;
								});
							});
						}
					}
				]
				#end
			});
		});
	};

	@:await static function firebaseInit() {
    final cfg = haxe.Json.parse(@:await boisly.AppSettings.config.firebase.svcCfg);
		FirebaseAdmin.initializeApp({
			credential: firebase_admin.Credential.cert(cfg)
			// databaseURL: boisly.AppSettings.config.firebase.databaseURL
		}, "fireduck");
	}

	public static var duck:Promise<bp.duck.Proxy> = getClient.next(client -> tink.Web.connect((AppSettings.config.duckApiUrl : bp.duck.proxy.WildDuckProxy),
		{client: client}));
	public static var pkapi:Promise<tink.web.proxy.Remote<PKAPI>> = getClient.next(client -> tink.Web.connect(('https://www.googleapis.com' : PKAPI),
		{client: client}));
	public static var publicKeys:Promise<haxe.DynamicAccess<String>> = pkapi.next(api -> api.getPublicKeys());
}

interface PKAPI {
	@:get('/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
	function getPublicKeys():Dynamic<String>;
}
