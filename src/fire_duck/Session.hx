package fire_duck;

import fire_duck.Connectors;

using fire_duck.Utils;

typedef User = {
	var duck:{
		> UserInfoResult, api:tink.web.proxy.Remote<UserProxy>
	};
	var fire:UserRecord;
}

@:await class Session {
	var header:IncomingRequestHeader;

	public function new(header)
		this.header = header;

	public function getUser():Promise<Option<User>>
		return doGetUser();

	@:async function doGetUser()
		return switch header.byName('x-access-token') {
			case Success(token):
				try {
					var api:tink.web.proxy.Remote<UserProxy> = null;
					var fire:Dynamic = @:await token.getFirebaseUser();
					var duck:Dynamic = try @:await ((api = (@:await Connectors.duck).users(@:await AppSettings.config.wildDuck.apiKey)
						.get((fire.customClaims : Dynamic).wildDuck.userId))).info() catch (e) null;
					duck.api = api;
					Some({
						fire: fire,
						duck: duck
					});
				} catch (e) {
					trace(e);
					None;
				}
			case Failure(e):
				trace(e);
				None;
		};
}
