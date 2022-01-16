package fire_duck;

// import boisly.AppSettings;
#if macro
import haxe.macro.Expr;
#end

typedef LoggerType = {trace:(Dynamic, ?haxe.PosInfos) -> Void};

class Logger {
	#if !macro
	public static var _logger:LoggerType = haxe.Log;

	public static dynamic function log(v:Dynamic, ?p:haxe.PosInfos)
		if (boisly.AppSettings.config.fireDuck.enableLogging)
			_logger.trace(v, p);
	#end

	public static macro function _(vs:Expr, e:Expr, ve:Array<Expr>) {
		return macro {
      
			fire_duck.Logger.log(${
				if (ve.length == 0)
					macro 'began ' + $vs
				else
					macro $vs
			}, null);
			var r = $e;
			fire_duck.Logger.log(${
				if (ve.length == 0)
					macro 'finished ' + $vs
				else
					macro ${ve[0]}
			}, null);
			r;
		}
	}

	public static inline macro function drop(vs:Expr, e:Expr, ve:Array<Expr>)
		return macro {
			fire_duck.Logger.log(${
				if (ve.length == 0)
					macro 'began ' + $vs
				else
					macro $vs
			}, null);
			$e;
			fire_duck.Logger.log(${
				if (ve.length == 0)
					macro 'finished ' + $vs
				else
					macro ${ve[0]}
			}, null);
		}
}
