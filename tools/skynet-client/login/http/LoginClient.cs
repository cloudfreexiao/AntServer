
using System;
using UnityEngine;
using CI.HttpClient;
using LitJson;

namespace Skynet.DotNetClient.Login.HTTP
{
    public delegate void LoginAuthRespCallBack(AuthPackageResp resp);

    public class LoginAuthHttp
    {
        private static HttpClient client =  new HttpClient(true);
        private static string url = "http://192.168.1.25:15110/api";
        private static LoginAuthRespCallBack respcb;

        //public static void ConfigureCertificate()
        //{
        //    System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls;
        //    System.Net.ServicePointManager.ServerCertificateValidationCallback = null;

        //    RemoteCertificateValidationCallback prevValidator;
        //    System.Net.SecurityProtocolType protocolType;

        //    ConfigureCertificateValidatation(false, out protocolType, out prevValidator);
        //}

        public static void Test()
        {
            client.Get(new Uri("https://api.weixin.qq.com/sns/userinfo"), HttpCompletionOption.AllResponseContent, (r) =>
            {
                if (r.IsSuccessStatusCode)
                {
                    string str = r.ReadAsString();
                    Debug.Log("responstr:" + str);
                    Debug.Log("+++++Test responstr+++++++++" + str);
                }
                else
                {
                    Debug.Log("statuscode:" + r.StatusCode.ToString());
                    Debug.Log("+++++Test statuscode+++++++++" + r.StatusCode.ToString());
                }
            });

        }

     //private static void ConfigureCertificateValidatation(
     //    bool validateCertificates,
     //    out System.Net.SecurityProtocolType protocolType,
     //    out RemoteCertificateValidationCallback prevValidator)
     //   {
     //       prevValidator = null;
     //       protocolType = (System.Net.SecurityProtocolType)0;

     //       if (!validateCertificates)
     //       {
     //           protocolType = System.Net.ServicePointManager.SecurityProtocol;
     //           System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls;
     //           prevValidator = System.Net.ServicePointManager.ServerCertificateValidationCallback;
     //           System.Net.ServicePointManager.ServerCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
     //       }
     //   }

        public static void DoLoginReqAction(AuthPackageReq cmd, LoginAuthRespCallBack cb)
        {
            respcb = cb;
            LoginwReqPack req = new LoginwReqPack();
            req.parms = JsonMapper.ToJson(cmd);
            string jsonStr = JsonMapper.ToJson(req);

            IHttpContent content = new StringContent(jsonStr, System.Text.Encoding.UTF8, "application/json");
            client.Post(new Uri(url), content, HttpCompletionOption.AllResponseContent, r =>
            {
                if (r.IsSuccessStatusCode)
                {
                    var respStr = r.ReadAsString();
                    try
                    {
                        AuthPackageResp resp = JsonMapper.ToObject<AuthPackageResp>(respStr);
                        respcb(resp);
                    }
                    catch(Exception e)
                    {
                        Debug.LogError("Json Deserialize err:" + e.Message.ToString());
                    }
                }
            });
        }
    }

}