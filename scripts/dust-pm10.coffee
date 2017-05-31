# Description:
#     당번이 할 일을 알려줍니다.
#
# Author: Leop0ld
#
# Commands:
#     미세먼지 등급표! - 미세먼지(pm10)의 등급표를 보여줍니다.
#     미세먼지! location - 지정한 위치의 미세먼지(pm10) 농도와 등급을 알려줍니다.

http = require 'http'
q = require 'q'

baseUrl = 'http://apis.skplanetx.com/weather/dust?version=1&appKey=e07f3817-4579-38e7-9dd5-3d9930e06fb9'

module.exports = (robot) ->
  robot.hear /미세먼지(등급표| 등급표)!/i, (msg) ->
    result_msg = "미세먼지 등급표(PM10)\n0~30: 좋음 :smile:\n31~80: 보통 :slightly_smiling_face:\n81~120: 약간나쁨 :angry:\n121~200: 나쁨 :rage:\n201~300: 매우나쁨 :scream:"
    msg.send result_msg

  robot.hear /미세먼지! (.*)/i, (msg) ->
    location = decodeURIComponent(unescape(msg.match[1]))
    getGeocode(msg, location)
    .then (geoCode) ->
        getDust(msg, geoCode, location)


  getGeocode = (msg, location) ->
    deferred = q.defer()
    robot.http("https://maps.googleapis.com/maps/api/geocode/json")
      .query({
        address: location
      })
      .get() (err, res, body) ->
        response = JSON.parse(body)
        geo = response.results[0].geometry.location
        if response.status is "OK"
          geoCode = {
            lat : geo.lat
            lng : geo.lng
          }
          deferred.resolve(geoCode)
        else
          deferred.reject(err)
    return deferred.promise

  getDust = (msg, geoCode, location) ->
    targetUrl = "#{baseUrl}&lat=#{geoCode.lat}&lon=#{geoCode.lng}"
    robot.http(targetUrl).get() (err, res, body) ->
      dataObj = JSON.parse(body).weather.dust[0]

      stationName = dataObj.station.name
      timeObservation = dataObj.timeObservation
      pm10Value = dataObj.pm10.value
      pm10Grade = dataObj.pm10.grade

      result_msg = "*#{timeObservation} 기준 #{stationName} 관측소 관측 결과* 입니다.\n"
      result_msg += "#{location}의 현재 미세먼지(PM10) 의 농도는 *#{pm10Value}㎍/㎥* 이며, 등급은 *#{pm10Grade}* 입니다."

      msg.send result_msg

