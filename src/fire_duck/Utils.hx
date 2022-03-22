package fire_duck;

using fire_duck.Utils;
using fire_duck.Logger;

import fire_duck.Logger.log;
import fire_duck.Logger;
import jsonwebtoken.Algorithm;

@:await class BusinessLogic {
	// public static inline function withLogging(v, s, e) Logger.doWithLogging(v, s, e);
	@:async public static function mkFirebaseUser(userInfo:UserInfoResult, duckProxy:bp.duck.Proxy) {
		if (userInfo.address == null)
			throw new Error(NotFound, "No email address found for user");

		log('Creating firebase user record for:');
		log(userInfo);
		var _auth:firebase_admin.lib.auth.auth.Auth = null;
		try {
			_auth = FirebaseAdmin.auth();
		} catch (e) {
			// I forgot why this was happening.. something about the type system
			log('failed to retrieve: $e');
			throw e;
		}
		var firebaseUserRecord:firebase_admin.lib.auth.user_record.UserRecord = try 'creating firebase user'._(@:await Promise.lift(_auth.createUser({
			email: userInfo.address,
			emailVerified: true,
			displayName: userInfo.name,
			uid: '${haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(AppSettings.config.wildDuck.idPrefix))}.${userInfo.id}'
		}))) catch (e) {
			e.details()._(throw Error.withData(500, "Firebase user creation error", e));
		}
		log("Got firebase user record");
		log(firebaseUserRecord);
		if (userInfo.metaData == null)
			userInfo.metaData = {};
		userInfo.metaData.firebaseUid = firebaseUserRecord.uid;
		var dynUserInfo:Dynamic = userInfo;
		dynUserInfo.ip = "0.0.0.0";
		dynUserInfo.sess = 'DuckMail API';
		// final apiKey = try 'retrieving api key'._(@:await AppSettings.config.wildDuck.apiKey) catch (e) {
		// 	e.details().drop(throw Error.withData(500, "Unable to retrieve API Key", e));
		// 	null;
		// }
		log('Updating WildDuck user metadata');
		var result = try 'updating WildDuck user metadata'._(@:await duckProxy.users().get(userInfo.id).update({metaData: userInfo.metaData})) catch (e) {
			log('WildDuck User Update Error:');

			e.details().drop(throw Error.withData(500, "WildDuck user update error", e));
			null;
		}
		log('Got user update result:');
		log(result);
		return if (!result.success) {
			throw new Error(cast result.code, "WildDuck user update error: " + result.error);
		} else {
			userInfo;
		}
	}

	@:async public static function getFirebaseUser(firebaseIdToken:String) {
		var config = AppSettings.config.wildDuck;
		var firebaseUserId = try @:await FirebaseAdmin.auth()
			.verifyIdToken(firebaseIdToken) catch (e) throw Error.withData("Firebase Id Verification Error: " + e.details(), e);
		var firebaseUser:UserRecord = try @:await FirebaseAdmin.auth()
			.getUser(firebaseUserId.uid) catch (e) throw Error.withData("Firebase User Retrieval Error", e);
		return firebaseUser;
	}

	@:async public static function auth(username:String, password:String, duckProxy:bp.duck.Proxy)
		/* :Promise<JwtAuthResult> */ {
		// final apiKey = try 'retrieving API key'._(@:await AppSettings.config.wildDuck.apiKey) catch (e) {
		// 	e.details()._(throw Error.withData(500, "Unable to retrieve API Key", e));
		// }
		final result = try {
			'authenticating WildDuck user'._(@:await duckProxy.auth().login({
				username: username,
				password: password
			}));
		} catch (e) {
			log('failed to authenticate');
			log(e);
			throw Error.withData(500, "WildDuck Error", e);
		}
		if (result.success)
			try {
				var userInfo = 'getting user info'._(@:await duckProxy.users().get(result.id).info());
				log('got user info');
				log(userInfo);
				final metaData = userInfo.metaData;
				var user:Dynamic = try 'getting firebase user'._(@:await FirebaseAdmin.auth().getUserByEmail(userInfo.address)) catch (_) null;
				log('got firebase user');
				log(user);
				var customClaims:Dynamic = if (user != null) user.customClaims else null;
				var updateClaims = false;
				var firebaseUid = metaData.firebaseUid;
				if (user == null || user.uid == null) {
					'making firebase user'._(@:await userInfo.mkFirebaseUser(duckProxy));
					user = try 'getting firebase user'._(@:await FirebaseAdmin.auth().getUserByEmail(userInfo.address)) catch (_) null;
					log('made firebase user');
				} else if (user.disabled) {
					log('user not authorized');
					throw new Error(Unauthorized, 'Unauthorized');
				}
					firebaseUid = user.uid;
				
				if (customClaims == null) {
					updateClaims = true;
					customClaims = {
						wildDuck: {
							userId: userInfo.id
						}
					}
				}
				if (customClaims.wildDuck.userId == null) {
					updateClaims = true;
					customClaims.wildDuck.userId = userInfo.id;
				}
				if (updateClaims) {
					try
						'updating custom claims'._(@:await FirebaseAdmin.auth().setCustomUserClaims(firebaseUid, customClaims))
					catch (e) {
						log("Couldn't update custom claims!");
						log(e);
						// throw Error.withData("Couldn't update custom claims", e);
					}
					log('custom claims updated');
				}
				var crypto = new NodeCrypto(); // pick a crypto from the jsonwebtoken.crypto package
				var signer = new BasicSigner(RS256({
					privateKey: 'reading private key'._(sys.io.File.getContent(AppSettings.config.firebase.privateKeyFile))
				}), crypto);
				var payload:FirebaseAuthJwt = {
					iss: AppSettings.config.firebase.svcAccountEmail,
					sub: AppSettings.config.firebase.svcAccountEmail,
					aud: AppSettings.config.firebase.audience,
					iat: Date.now(),
					exp: {
						final now = Date.now();
						new Date(now.getFullYear(), now.getMonth(), now.getDay() - 1, now.getHours() + 1, now.getMinutes(), now.getSeconds());
					},
					nbf: Date.now(),
					uid: Std.string(user.uid)
				};
				payload.claims = customClaims;
				return try 'signing claims payload...'._(@:await signer.sign(payload).next(token -> ({
					success: true,
					token: token
				}))) catch (e) {
					log('couldnt sign claims');
					log(e.details());
					throw Error.withData("Unable to sign claims", e);
				};
			} catch (e)
				throw Error.withData('Something went wrong!', e)
		else {
			log(result);
			throw new Error(cast result.code, result.error);
		}
	}
}
