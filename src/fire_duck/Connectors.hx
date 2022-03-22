package fire_duck;

@:await class Connectors {
	static var getClient:Promise<tink.http.Client> = {
		var client:tink.http.Client = new NodeClient();
		trace(boisly.AppSettings.config);
		var getApiKey:Promise<tink.Chunk> = AppSettings.config.wildDuck.apiKey;
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
								fire_duck.Logger.log(req.header);
								try {
									fire_duck.Logger.log(body);
								} catch (e) {
									fire_duck.Logger.log('Couldnt print body: ${e.details()}');
								}
								res.body.all().next(body -> {
									fire_duck.Logger.log(res.header);
									try {
										fire_duck.Logger.log(body);
									} catch (e) {
										fire_duck.Logger.log('Couldnt print body: ${e.details()}');
									}
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
		trace('w0t');
		trace(FirebaseAdmin.apps);
		if (AppSettings.config.firebase.standalone && FirebaseAdmin.apps.length <= 1) {
			trace('Initializing app...');
			FirebaseAdmin.initializeApp({
				credential: firebase_admin.Credential.cert(cfg) // databaseURL: boisly.AppSettings.config.firebase.databaseURL
			});

			FirebaseAdmin.initializeApp({
				credential: firebase_admin.Credential.cert(cfg) // databaseURL: boisly.AppSettings.config.firebase.databaseURL
			}, "fireduck");
		}
	}

	public static var duck:Promise<bp.duck.Proxy> = getClient.next(client -> tink.Web.connect((AppSettings.config.duckApiUrl : bp.duck.proxy.WildDuckProxy), {
		client: client
	}));
	public static var pkapi:Promise<tink.web.proxy.Remote<PKAPI>> = getClient.next(client -> tink.Web.connect(('https://www.googleapis.com' : PKAPI), {
		client: client
	}));
	public static var publicKeys:Promise<haxe.DynamicAccess<String>> = pkapi.next(api -> api.getPublicKeys());
}

interface PKAPI {
	@:get('/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
	function getPublicKeys():Dynamic<String>;
}
