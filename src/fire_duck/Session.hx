package fire_duck;
import fire_duck.Connectors;
using fire_duck.Utils;

typedef User = {
    var duck:UserInfoResult;
    var fire:UserRecord;
}
@:await class Session {
    var header:IncomingRequestHeader;
    
    public function new(header)
        this.header = header;
    public function getUser():Promise<Option<User>> return doGetUser();
    @:async  function doGetUser()
        return switch header.byName('x-access-token') {
            case Success(token):
                try {

                    var fire:Dynamic = @:await token.getFirebaseUser();
                    var duck:Dynamic = try @:await (@:await Connectors.duck).users(@:await AppSettings.config.wildDuck.apiKey).get((fire.customClaims : Dynamic).wildDuck.userId).info() catch(e) null;               
                    Some({
                        fire: fire,
                        duck: duck
                    });
                } catch(e) {
                    trace(e);
                    None;
                }
            case Failure(e):
                trace(e);
                None;
        };
}