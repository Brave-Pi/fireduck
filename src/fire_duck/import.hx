#if !macro
import js.node.http.IncomingMessage;
import bp.duck.proxy.models.Results;
import bp.duck.proxy.WildDuckProxy;
import FirebaseAdmin;
import firebase_admin.lib.auth.user_record.UserRecord;
import tink.core.Error;
import tink.CoreApi;
import tink.io.Source.IdealSource;
import bp.duck.proxy.models.Results;
import bp.duck.proxy.models.Requests;
import boisly.Secret;
import js.node.http.ServerResponse;
import tink.web.routing.*;
import fire_duck.Config;
import jsonwebtoken.signer.*;
import jsonwebtoken.crypto.*;
import tink.http.Response;
import tink.http.Request;
import tink.http.clients.*;
import boisly.AppSettings;
import fire_duck.Types;
import fire_duck.Logger;

using tink.io.Source;
import tink.Url;
import tink.http.Header;
import tink.http.Request;
import tink.http.Response;
#end