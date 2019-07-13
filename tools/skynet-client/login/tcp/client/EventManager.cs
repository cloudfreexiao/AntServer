namespace Skynet.DotNetClient.Login.TCP
{
    using System;
    using System.Text;
    using System.Text.RegularExpressions;
    using Util;
    using UnityEngine;
    
    public class EventManager : IDisposable
    { 
        private event Action<int, AuthPackageResp> OnLoginCallBack;
        private Login_Auth_State _state;
        private readonly AuthPackageReq _req;
        private readonly LoginClient _client;
        private readonly AuthChallenge _challenge;
        
        public EventManager(AuthPackageReq req, Action<int, AuthPackageResp> loginCallBack, LoginClient c)
        {
            _challenge = new AuthChallenge();

            _state = Login_Auth_State.GET_CHALLENGE;
            _req = req;
            _client = c;
            OnLoginCallBack = loginCallBack;
        }

        public void InvokeCallBack(byte[] bytes)
        {
            string msg = Encoding.UTF8.GetString(bytes);
            switch (_state)
            {
                case Login_Auth_State.GET_CHALLENGE:
                    GetChallenge(msg);
                    break;
                case Login_Auth_State.GET_SECRET:
                    GetSecret(msg);
                    break;
                case Login_Auth_State.LOGIN_RESULT:
                    OnLoginResult(msg);
                    break;
            }
        }

        private void GetChallenge(string socketline)
        {
            byte[] challengeByte = Crypt.Base64Decode(socketline);
            if (challengeByte.Length == 8)
            {
                _challenge.challenge = challengeByte;
                byte[] dhkey = Crypt.RandomKey();
                _challenge.clientkey = Crypt.DHExchange(dhkey);
                Request(_challenge.clientkey);

                _state = Login_Auth_State.GET_SECRET;
            }
        }
        
        private void GetSecret(string socketstr)
        {
            byte[] lineByte = Crypt.Base64Decode(socketstr);
            if (lineByte.Length == 8)
            {
                byte[] serverkey = lineByte; //Crypt.DHExchange(lineByte);
//                Debug.Log("dhkey: " + Crypt.HexEncode(serverkey));

                _challenge.secret = Crypt.DHSecret(_challenge.clientkey, serverkey);;
//                Debug.Log("secret: " + Crypt.HexEncode(_challenge.secret));

                byte[] hmackey = Crypt.HMAC64(_challenge.challenge, _challenge.secret);
//                Debug.Log("hmac: " + Crypt.HexEncode(hmackey));

                Request(hmackey);
                
                _state = Login_Auth_State.SEND_LOGIN;
                
                DoLoginAction();
            }
        }
        
        public void DoLoginAction()
        {
            string token = EncodeToken(_req);
            byte [] etoken = Crypt.DesEncode(_challenge.secret, Encoding.UTF8.GetBytes(token));
            Request(etoken);
            _state = Login_Auth_State.LOGIN_RESULT;
        }
        
        private void OnLoginResult(string socketstr)
        {
            AuthPackageResp resp = new AuthPackageResp();

            int code = int.Parse(socketstr.Substring(0, 3));
            byte[] subidByte = Crypt.Base64Decode(socketstr.Substring(4));
            string resultString = Encoding.UTF8.GetString(subidByte);
            if (code == 200)
            {
                string[] split = Regex.Split(resultString, "['$']");
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
            _state = Login_Auth_State.LOGIN_FINISHED;
            OnLoginCallBack.Invoke(code, resp);
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
            string base64key = Crypt.Base64Encode(buf) + '\n';
            byte[] message = Encoding.UTF8.GetBytes(base64key);
            _client.Request(message);
        }
        
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected void Dispose(bool disposing)
        {
        }

    }
}