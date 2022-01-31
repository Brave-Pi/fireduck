using fire_duck.Logger;
using fire_duck.Utils;
using tink.CoreApi;

import fire_duck.Types;
import fire_duck.Session;
import tink.http.containers.*;
import tink.http.Response;
import tink.web.routing.*;

@:await class FireDuck {
	@:await static function main() {
		// 'testing'._(trace('test'));
		final router = new Router<Session, Root>(new Root());
		final handler = req -> router.route(Context.authed(req, cast Session.new)).recover(OutgoingResponse.reportError);
		// final nodeHandler = #if (tink_http >= "0.10.0") this.handler.toNodeHandler.bind({}) #else NodeContainer.toNodeHandler.bind(this.handler, {}) #end;
		final container = new NodeContainer(8080);
		container.run(handler);
		final cfg = haxe.Json.parse(@:await boisly.AppSettings.config.firebase.svcCfg);
		FirebaseAdmin.initializeApp({
			credential: firebase_admin.Credential.cert(cfg) // databaseURL: boisly.AppSettings.config.firebase.databaseURL
		});
	}
}

@:await class Root {
	public function new() {}

	@:post('/login')
	@:async public function login(body:{username:String, password:String}):JwtAuthResult
		return try @:await body.username.auth(body.password, @:await fire_duck.Connectors.duck) catch (e) throw Error.withData("Unable to login", e);

	@:get('/test')
	@:async public function test(user:User) {
		return try @:await user.duck.api.addresses() catch (e) throw Error.withData("Unable to get user addresess", e);
	}
}

@:config
class Config extends fire_duck.Config {}
