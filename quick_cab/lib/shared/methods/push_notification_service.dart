import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:quick_cab/appinfo/app_info.dart';
import 'package:quick_cab/gloabal/global_var.dart';

class PushNotificationService
{
  static Future<String> getAccessToken() async
  {
    final serviceAccountJson =
    {
      "type": "service_account",
      "project_id": "quickcab-b8b8a",
      "private_key_id": "992fe5c3e9572867dfcf2e49661e5d458c3157ca",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCtroiw5HL+mICW\n+4AWNZIFVrlPYLrOXikolVdJWNB4UbrpB53XkjhHZQlKtQ/haOX+8yb/RyHTntDp\n8d9OSPCTcVrHk/mRPWzulVjeZLHaVyiuEc7GKKxlxv5AQTH9b9TShFf8dTsdZCUw\nW5voU5lkxVa3kDPLcb421bb2OEoUe/+eAhjupbJRQrtG6v+bYHIAOOk/9WXLajZK\nWjJhL7j+FqlVKz9cWCedlVJhdRK1o3WDQkAmPEPraDo+6Iq0iRsPM0vVwgP+bN4q\nj+t8IryawjD+8KLvpUz0Co/aYAn7SF3mLCzJ39PwdN5mBtep5bfzaRAZrDW2o/+H\nD8PiEtmhAgMBAAECggEAG1BH4d3DceOE0Xmy3otFL/6//Mo/BoZLXb0CsZ+8hTeB\nN/WBLq4pmJy8ldmcqjvHc81EdD/5A2FGBIyLrDGPV/irKJjOVjd9QpYNGEhoqegs\nFxfo10P9PLJLOMqn9G3aX9L9TVAYYFpn+M9nWOWQyYa5SPvuEVANdG0urVET4V2O\ncjZMhLNQUida3Db3UMNTzITb+yPTqO6CopHl+dcfCRAa6Nul/mH7zpCfnpeo6mDd\nZNSmrpTxvlSiTx6CNCnyq6TcLjr6sif/5+itDSy6E5kP/wSHEdNwk7h6MpXUM7Km\nq4msfNv+RDTiFF/57zTcr0MrGsADSm8qj57xqrjF8wKBgQDXsaamdcnfQ5fbGicR\nV7UTptqy1BWnMhFSPr0L9jb69M3GH/Y5/zlRXHWd5zU9G475s7xOlcVO5MrHbd9T\niGcJAivEAqFvpf8E8uTdBIjBMoxLtMxSqSI6qpHfQh0gE9eIPPMKdeaeVCWpiVlB\ngUzU/F/Q00A2WbJuTaUSZmcw+wKBgQDOIxun2biqK3HYf3uGcgCgNnQLuUODnPUA\nFhUh2qGvkCrx9oNHaLh/Ll9TIRvXyWc27Zbe8SI8l3oy7NXEPU4moKHx1YH/qFrr\nfRPwWp7IOAhNSYhfxBigq7tiPVOGDUYT/TG7RX40gBOWJhZiwBftQe2t9VVBtWID\nHW+UUX71EwKBgQCORWPDEJajaZZUsx9p1QxfdgNzSWku61t5gGB572G8jpTcRmDH\nSI2qGO6LxOHc+LyKAAAJZcjLjSYj/Vj9ZE9yJbhwhbuuRTO9M+m5zy/VH15i4VKU\ng3NMdw3Y0WccrXnRJ0K4d6QycxaUiUAScRMYuY8J0w3by7ZiA10Kkfkm2QKBgGLp\nd8C/+Rs2g4dGDKjDlUdLOb3SZPIHY4xqDDPVa9YJUIIQLogaWMU2JCmIborJqowx\nzz4k6K+4Y7uB50UlwZVJaMvZDmr1hsMOnn2rjhs2v80OJrEFMGgQX3bRRH3Dasf2\nq2FYBCn+9ucKWZ2C3ThMdVcOrJ0+AszJ2BuMS2YfAoGAbxTAIACNkY5jT85fUznn\nqvgYzoAKXg70cj3jP/TYbL5I545MkqKmYWAcaV6prtZPPs5aLGLjvV+LRXLUX7vd\nNy/SgW6x1nV77aoUwSv6LEltTsnBwA7HdD5DFPU6YEcNhpH+MDnbE1/uvj26tiam\nnVvJnXgLbZcTGiMXalusIW8=\n-----END PRIVATE KEY-----\n",
      "client_email": "quickcabvips@quickcab-b8b8a.iam.gserviceaccount.com",
      "client_id": "101061126400444775844",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/quickcabvips%40quickcab-b8b8a.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes =
    [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    //get the access token
    auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      client
    );

    client.close();

    return credentials.accessToken.data;
  }

  static sendNotificationToSelectedDriver(String deviceToken, BuildContext context, String tripID) async
  {
    String dropOffDestinationAddress = Provider.of<AppInfo>(context, listen: false).dropOffLocation!.placeName.toString();
    String pickUpAddress = Provider.of<AppInfo>(context, listen: false).pickUpLocation!.placeName.toString();

    final String serverAccessTokenKey = await getAccessToken() ; // Your FCM server access token key
    String endpointFirebaseCloudMessaging = 'https://fcm.googleapis.com/v1/projects/quickcab-b8b8a/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken, // Token of the device you want to send the message/notification to
        'notification': {
          "title": "NET TRIP REQUEST from $userName",
          "body": "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDestinationAddress",
        },
        'data': {
          "tripID": tripID,
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessTokenKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }
}