#!/bin/bash
export LANG=zh_CN.UTF-8
auth_email="XXXXXXX@gmail.com"    #你的CloudFlare注册账户邮箱
auth_key="XXXXXXXXxxxx"   #你的CloudFlare账户key,位置在域名概述页面点击右下角获取api key。
zone_name="xxxx.eu.org"     #你的主域名
record_name="00011c"    #自动更新的二级域名前缀,例如cloudflare的cdn用00011c，gcore的cdn用00011g，后面是数字，程序会自动添加。二级域名需要已经在域名管理网站配置完成，视频教程可以参考：
record_count=5 #二级域名个数，例如配置5个，则域名分别是00011c1、00011c2、00011c3、00011c4、00011c5. 最后的域名格式是：00011c1.xxx.eu.org  后面的信息均不需要修改，让他自动运行就好了。



# 显式设置PATH变量，包括CloudflareST所在的路径,此处是绝对路径。
export PATH="$PATH:/root/orzl_speed/CloudflareST"
# 获取脚本所在的目录
script_dir="$(cd "$(dirname "$0")" && pwd)"
# 切换到脚本所在的目录
cd "$script_dir"


echo
echo '你的IP地址是'$(curl 4.ipw.cn)',请确认为本机未经过代理的地址'
echo '智深博客：https://www.bigniuniu.top'
./CloudflareST -url https://ce.zsblog.eu.org

record_type="A"     
#获取zone_id、record_id
zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
#echo $zone_identifier

sed -n '2,20p' result.csv | while read line
do
    #echo $record_name$record_count'.'$zone_name
    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name$record_count"'.'"$zone_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    #echo $record_identifier
    #更新DNS记录
    update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"type\":\"$record_type\",\"name\":\"$record_name$record_count.$zone_name\",\"content\":\"${line%%,*}\",\"ttl\":60,\"proxied\":false}")
    #反馈更新情况
    if [[ "$update" != "${update%success*}" ]] && [[ "$(echo $update | grep "\"success\":true")" != "" ]]; then
      echo $record_name$record_count'.'$zone_name'更新为:'${line%%,*}'....成功'
    else
      echo $record_name$record_count'.'$zone_name'更新失败:'$update
    fi

    record_count=$(($record_count-1))    #二级域名序号递减
    echo $record_count
    if [ $record_count -eq 0 ]; then
        break
    fi

done
