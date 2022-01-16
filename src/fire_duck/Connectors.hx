package fire_duck;

class Connectors {
	static var getClient:Promise<tink.http.Client> = {
		var client:tink.http.Client = new NodeClient();
		var getApiKey:Promise<tink.Chunk> = AppSettings.config.wildDuck.apiKey;
		getApiKey.next(apiKey -> client.augment({
			before: [
				req -> {
					@:privateAccess req.header.fields.push(new HeaderField("x-access-token", apiKey));
					req;
				}
			]
		}));
	};
	public static var duck:Promise<bp.duck.Proxy> = getClient.next(client -> tink.Web.connect((AppSettings.config.duckApiUrl : bp.duck.proxy.WildDuckProxy), {client: client}));
}
