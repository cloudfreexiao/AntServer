namespace Skynet.DotNetClient.Login.TCP
{
    using System;
    using System.Text;
    using System.Text.RegularExpressions;
    using Utils.Crypt;
    
    public class EventManager : IDisposable
    { 
        private event Action<int, AuthPackageResp> OnLoginCallBack;
        private LoginAuthState _state;
        private readonly AuthPackageReq _req;
        private readonly LoginClient _client;
        private readonly AuthChallenge _challenge;
        
        public EventManager(AuthPackageReq req, Action<int, AuthPackageResp> loginCallBack, LoginClient c)
        {
            _challenge = new AuthChallenge();

            _state = LoginAuthState.GetChallenge;
            _req = req;
            _client = c;
            OnLoginCallBack = loginCallBack;
        }

        public void InvokeCallBack(byte[] bytes)
        {
            var msg = Encoding.UTF8.GetString(bytes);
            switch (_state)
            {
                case LoginAuthState.GetChallenge:
                    GetChallenge(msg);
                    break;
                case LoginAuthState.GetSecret:
                    GetSecret(msg);
                    break;
                case LoginAuthState.LoginResult:
                    LoginResult(msg);
                    break;
                case LoginAuthState.Nil:
                    break;
                case LoginAuthState.SendLogin:
                    break;
                case LoginAuthState.LoginFinished:
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        private void GetChallenge(string socketline)
        {
            var challengeByte = Crypt.Base64Decode(socketline);
            if (challengeByte.Length != 8) return;
            _challenge.challenge = challengeByte;
            var dhkey = Crypt.RandomKey();
            _challenge.clientkey = Crypt.DHExchange(dhkey);
            Request(_challenge.clientkey);

            _state = LoginAuthState.GetSecret;
        }
        
        private void GetSecret(string socketstr)
        {
            var lineByte = Crypt.Base64Decode(socketstr);
            if (lineByte.Length != 8) return;
            var serverkey = lineByte; //Crypt.DHExchange(lineByte);
//                Debug.Log("dhkey: " + Crypt.HexEncode(serverkey));

            _challenge.secret = Crypt.DHSecret(_challenge.clientkey, serverkey);;
//                Debug.Log("secret: " + Crypt.HexEncode(_challenge.secret));

            var hmackey = Crypt.HMAC64(_challenge.challenge, _challenge.secret);
//                Debug.Log("hmac: " + Crypt.HexEncode(hmackey));

            Request(hmackey);
                
            _state = LoginAuthState.SendLogin;
                
            DoLoginAction();
        }

        private void DoLoginAction()
        {
            var token = EncodeToken(_req);
            var etoken = Crypt.DesEncode(_challenge.secret, Encoding.UTF8.GetBytes(token));
            Request(etoken);
            _state = LoginAuthState.LoginResult;
        }
        
        private void LoginResult(string socketstr)
        {
            AuthPackageResp resp = new AuthPackageResp();

            var code = int.Parse(socketstr.Substring(0, 3));
            var subidByte = Crypt.Base64Decode(socketstr.Substring(4));
            var resultString = Encoding.UTF8.GetString(subidByte);
            if (code == 200)
            {
                var split = Regex.Split(resultString, "['$']");
                resp.gate = split[0];
                resp.port = Int32.Parse(split[1]);
                resp.uid = split[2];
                resp.secret = split[3];
                resp.subid = split[4];
            }
//            Debug.Log("login result code:" + code);
//            Debug.Log("login result gate:" + resp.gate);
//            Debug.Log("login result port:" + resp.port);
//            Debug.Log("login result uid:" + resp.uid);
//            Debug.Log("login result subid:" + resp.subid);
//            Debug.Log("login result secret:" + resp.secret);
            _state = LoginAuthState.LoginFinished;
            OnLoginCallBack?.Invoke(code, resp);
        }
        
        private string EncodeToken(AuthPackageReq auth_package)
        {
            return string.Format("{0}${1}${2}${3}${4}${5}", 
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.openId)),
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.sdk)),
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.serverId)),
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.pf)),
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.protocol)),
                Crypt.Base64Encode(Encoding.UTF8.GetBytes(auth_package.userData))
                );
        }
        
        private void Request(byte[] buf)
        {
            var base64key = Crypt.Base64Encode(buf) + '\n';
            var message = Encoding.UTF8.GetBytes(base64key);
            _client.Request(message);
        }
        
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
        }

    }
}