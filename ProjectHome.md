ruby api for china mobile's fetion　最简单的飞信客户端，仅支持TCP方式发短信。
仅提供如下几个个接口:
  * send\_sms
  * send\_sms\_to\_self
  * keep\_alive(&callback) #保持连接,可接收消息

```
   fetion = Fetion.new "phone_num","password"
   fetion.login

   #fetion.send_sms_to_self "test-ruby-fetion-中文"
   #fetion.send_sms "13651368727","any sms"

   #fetion.keep_alive

   fetion.keep_alive{|res|
      data = res.split(/\r\n\r\n/)
      if data[data.size - 2] && data[data.size - 2][0] == 'M'[0]
         puts "\n*********** Msg received :************\n#{data[data.size - 1]}"
      end
   }

   #fetion.logout
```


## 2012-06-13 更新,又可以工作了 ##
登录时rsa加密部分参考了pyfetion（http://code.google.com/p/pytool/source/browse/#svn%2Ftrunk%2FPyFetion 可以正常登录）和rfetion（https://github.com/flyerhzm/rfetion/blob/master/lib/rfetion/fetion.rb#L530 已经不能正常登录）的实现，外加自己的推测。

## todo ##
  * IO层计划使用EventMachine重构;