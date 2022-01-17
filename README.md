# FireDuck

A tink_web session leveraging WildDuck+Firebase/Google Identity.

# Usage

```haxe
import fire_duck.Session;
final router = new Router<Session, Root>(new Root());
final handler = req -> router.route(Context.authed(req, cast Session.new)).recover(OutgoingResponse.reportError);
container.run(handler);
```

This injects a FireDuck `User` into your `tink_web` router.
```haxe
typedef User = {
    var fire:UserRecord;
    var duck:{
        > UserInfoResult, api:tink.web.proxy.Remote<UserProxy>
    };
}
```

See:
- [`firebase_admin.lib.auth.user_record.UserRecord`](https://github.com/piboistudios/firebase-admin/blob/master/firebase_admin/lib/auth/user_record/UserRecord.hx)
- [`bp.duck.proxy.models.Results.UserInfoResult`](https://github.com/Brave-Pi/bp_duck/blob/45379ff50a29f00337a010b785eea4a94f7d56d0/src/bp/duck/proxy/models/Results.hx#L60)
- [bp.duck.proxy.UserProxy](https://github.com/Brave-Pi/bp_duck/blob/45379ff50a29f00337a010b785eea4a94f7d56d0/src/bp/duck/proxy/WildDuckProxy.hx#L150)