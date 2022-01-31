package fire_duck;

import fire_duck.Connectors;

using fire_duck.Utils;

typedef User = {
	var fire:UserRecord;
	var duck:{
		> UserInfoResult, api:tink.web.proxy.Remote<UserProxy>
	};
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
					var duck:Dynamic = try @:await ((api = (@:await Connectors.duck).users()
						.get((fire.customClaims : Dynamic).wildDuck.userId))).info() catch (e) {};
					duck.api = api;
					Some({
						fire: fire,
						duck: duck
					});
				} catch (e) {
					log(e.details());
					throw Error.withData('Unable to authenticate', e);
				}
			case Failure(e):
				None;
		};
}
