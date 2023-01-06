library flutter_client_sse;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
part 'sse_event_model.dart';

class SSEClient {
  static http.Client _client = new http.Client();

  ///def: Subscribes to SSE
  ///param:
  ///[url]->URl of the SSE api
  ///[header]->Map<String,String>, key value pair of the request header
  static Stream<SSEModel> subscribeToSSE(
      {required String url, required Map<String, String> header}) {
    var lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
    var currentSSEModel = SSEModel(data: '', id: '', event: '');
    // ignore: close_sinks
    StreamController<SSEModel> streamController = new StreamController();
    print("--SUBSCRIBING TO SSE---");
    while (true) {
      try {
        _client = RetryClient(
          http.Client(),
          onRetry: (p0, p1, retryCount) {
            debugPrint("onRetry:$p0, $p1, $retryCount");
            streamController.addError("onRetry");
          },
        );
        var request = new http.Request("GET", Uri.parse(url));

        ///Adding headers to the request
        header.forEach((key, value) {
          request.headers[key] = value;
        });

        Future<http.StreamedResponse> response = _client.send(request);

        ///Listening to the response as a stream
        response.asStream().listen(
          (data) {
            ///Applying transforms and listening to it
            debugPrint('---statusCode---:${data.statusCode}');
            if (data.statusCode != 200) {
              debugPrint('response ---ERROR--- :${data.statusCode}');
              streamController.addError(data.statusCode);
            } else {
              data.stream
                ..transform(Utf8Decoder()).transform(LineSplitter()).listen(
                  (dataLine) {
                    if (dataLine.isEmpty) {
                      ///This means that the complete event set has been read.
                      ///We then add the event to the stream
                      streamController.add(currentSSEModel);
                      currentSSEModel = SSEModel(data: '', id: '', event: '');
                      return;
                    }

                    ///Get the match of each line through the regex
                    Match match = lineRegex.firstMatch(dataLine)!;
                    var field = match.group(1);
                    if (field!.isEmpty) {
                      return;
                    }
                    var value = '';
                    if (field == 'data') {
                      //If the field is data, we get the data through the substring
                      value = dataLine.substring(
                        5,
                      );
                    } else {
                      value = match.group(2) ?? '';
                    }
                    switch (field) {
                      case 'event':
                        currentSSEModel.event = value;
                        break;
                      case 'data':
                        currentSSEModel.data =
                            (currentSSEModel.data ?? '') + value + '\n';
                        break;
                      case 'id':
                        currentSSEModel.id = value;
                        break;
                      case 'retry':
                        break;
                    }
                  },
                  onError: (e, s) {
                    if ("$e" != "Connection closed while receiving data") {
                      debugPrint('stream transform ---ERROR--- :$e');
                      streamController.addError(e, s);
                    }
                  },
                  onDone: () {
                    debugPrint('stream transform onDone');
                  },
                );
            }
          },
          onError: (e, s) {
            debugPrint('response ---ERROR--- :$e');
            streamController.addError(e, s);
          },
          onDone: () {},
        );
      } catch (e, s) {
        debugPrint('_client try ---ERROR--- :$e');
        streamController.addError(e, s);
      }

      Future.delayed(Duration(seconds: 1), () {});
      return streamController.stream;
    }
  }

  static void unsubscribeFromSSE() {
    _client.close();
  }
}
