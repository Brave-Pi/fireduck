package fire_duck;

class Config extends boisly.gatekeeper.Config.AppConfig {
	public var fireDuck:{
		enableLogging:Bool
	}
	public var duckApiUrl:String;
	public var wildDuck:{
		apiKey:boisly.Secret,
		domain:String,
		idPrefix:String,
		registrationEnabled:Bool,
		reservedUsernames:Array<String>,
		newUser:{
			recipients:Int,
			forwards:Int,
			quota:Int
		}
	};
	public var firebase:{
		svcAccountEmail:String,
		audience:String,
		privateKeyFile:String,
    standalone:Bool,
    svcCfg:Dynamic,
    databaseURL:String
	};
}
