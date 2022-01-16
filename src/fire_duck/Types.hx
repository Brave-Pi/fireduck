package fire_duck;
typedef JwtAuthResult = {
	success:Bool,
	?token:String,
}

typedef FirebaseAuthJwt = {
	> jsonwebtoken.Claims,
	?uid:String,
	?claims:Dynamic
}

typedef UserCreationInfo = {
    displayName:String,
    username:String,
    password:String
}