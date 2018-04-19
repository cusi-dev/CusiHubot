# Description:
#   Script to pull data from Footprints
#
# Notes:
#
request = require("request")
xml2js = require("xml2js")
processors = require('xml2js/lib/processors')
util = require('util')
Entities = require('html-entities').XmlEntities;
entities = new Entities();

module.exports = (robot) ->
  robot.respond /status/i , (res) ->
    res.send "I have retrieved #{robot.brain.get('FootPrintRequestsServed') || '0'} tickets from FootPrints."

  robot.hear /fp(\d+)(?!-)\b/i, (res) ->
    FootPrintRequestsServed = robot.brain.get('FootPrintRequestsServed') || 0
    options =
      method: 'POST',
      url: process.env.FP_URL,
      headers:
        'Cache-Control': 'no-cache',
        'Content-Type': 'text/xml',
      body: '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:namesp2="http://xml.apache.org/xml-soap" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"><SOAP-ENV:Header/><SOAP-ENV:Body> <namesp1:MRWebServices__getIssueDetails xmlns:namesp1="MRWebServices"><user xsi:type="xsd:string">'+ "#{process.env.FP_USER_ID}" +'</user><password xsi:type="xsd:string">'+ process.env.FP_PASSWORD + '</password> <extrainfo xsi:type="xsd:string"/> <projectnumber xsi:type="xsd:int">' + process.env.FP_ProjectNumber + '</projectnumber> <mrid xsi:type="xsd:int">'+res.match[1]+'</mrid> </namesp1:MRWebServices__getIssueDetails> </SOAP-ENV:Body> </SOAP-ENV:Envelope>'

    request(options, (err,result,body) ->
      if result is undefined
        robot.adapter.client.web.reactions.add('boterror', {channel: res.message.room, timestamp: res.message.id})
        robot.adapter.client.web.chat.postMessage(
          res.message.user.room,
          "`Unable  to communicate with server`",
          {thread_ts: res.message.rawMessage.thread_ts || res.message.rawMessage.ts}
        );
        return
      rerror = /Server Error/ig
      res.send "Login Error: \n#{options.body}" if (body.search(rerror) > -1)

      xml2js.parseString(body, {tagNameProcessors: [processors.stripPrefix, processors.normalize], normalize: true}, (err, result) ->
        ticket = result.envelope.body[0].mrwebservices__getissuedetailsresponse[0].return[0]
        try
          obj =
            ID: ticket.mr[0]._,
          obj.color = switch
            when ticket.priority[0]._ == '1' then 'danger'
            when ticket.priority[0]._ == '2' then 'warning'
            when ticket.priority[0]._ == '3' then 'good'
            else "#000000"
          obj.title = entities.decode(ticket.title[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.status = entities.decode(ticket.status[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.assignee = entities.decode(ticket.assignees[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.company = entities.decode(ticket.company[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.requestor = "#{ticket.first__bname[0]._} #{ticket.last__bname[0]._}";
          obj.URL = "http://support.cusi.com/MRcgi/MRlogin.pl?DL=#{obj.ID}DA4"

          message =
            {
              "attachments": [
                  {
                      "fallback": "#{obj.ID}: obj.title",
                      "color": obj.color,
                      "title": "Issue #{obj.ID}",
                      "text": "#{obj.title}",
                      "title_link": "#{obj.URL}",
                      "fields": [
                          {
                              "title": "Status",
                              "value": "#{obj.status}",
                              "short": true
                          },
                          {
                              "title": "Assignee",
                              "value": "#{obj.assignee}",
                              "short": true
                          },
                          {
                              "title": "Company",
                              "value": "#{obj.company}",
                              "short": true
                          },
                          {
                              "title": "Requestor",
                              "value": "#{obj.requestor}",
                              "short": true
                          }
                      ],
                      "footer": "Footprints",
                      "footer_icon": "https://communities.bmc.com/themes/bmc-global/favicon.ico",
                  }
              ]
            }
          res.send message
          robot.brain.set('FootPrintRequestsServed', FootPrintRequestsServed+1)
        catch error
          console.log "There was an error"
      )
    )

  robot.hear /fp(\d+)-/i, (res) ->
    FootPrintRequestsServed = robot.brain.get('FootPrintRequestsServed') || 0
    options =
      method: 'POST',
      url: process.env.FP_ProjectNumber,
      headers:
        'Cache-Control': 'no-cache',
        'Content-Type': 'text/xml',
      body: '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:namesp2="http://xml.apache.org/xml-soap" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/"><SOAP-ENV:Header/><SOAP-ENV:Body> <namesp1:MRWebServices__getIssueDetails xmlns:namesp1="MRWebServices"><user xsi:type="xsd:string">'+ "#{process.env.FP_USER_ID}" +'</user><password xsi:type="xsd:string">'+ process.env.FP_PASSWORD + '</password> <extrainfo xsi:type="xsd:string"/> <projectnumber xsi:type="xsd:int">' + process.env.FP_ProjectNumber + '</projectnumber> <mrid xsi:type="xsd:int">'+res.match[1]+'</mrid> </namesp1:MRWebServices__getIssueDetails> </SOAP-ENV:Body> </SOAP-ENV:Envelope>'

    request(options, (err,result,body) ->
      if result is undefined
        robot.adapter.client.web.reactions.add('boterror', {channel: res.message.room, timestamp: res.message.id})
        robot.adapter.client.web.chat.postMessage(
          res.message.user.room,
          "`Unable  to communicate with server`",
          {thread_ts: res.message.rawMessage.thread_ts || res.message.rawMessage.ts}
        );
        return
      rerror = /Server Error/ig
      res.send "Login Error: \n#{options.body}" if (body.search(rerror) > -1)

      xml2js.parseString(body, {tagNameProcessors: [processors.stripPrefix, processors.normalize], normalize: true}, (err, result) ->
        ticket = result.envelope.body[0].mrwebservices__getissuedetailsresponse[0].return[0]
        try
          obj =
            ID: ticket.mr[0]._,
          obj.color = switch
            when ticket.priority[0]._ == '1' then 'danger'
            when ticket.priority[0]._ == '2' then 'warning'
            when ticket.priority[0]._ == '3' then 'good'
            else "#000000"
          obj.priority = switch
            when ticket.priority[0]._ == '1' then 'Blocker'
            when ticket.priority[0]._ == '2' then 'Major'
            when ticket.priority[0]._ == '3' then 'Minor'
            else "#000000"
          obj.title = entities.decode(ticket.title[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.status = entities.decode(ticket.status[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.assignee = entities.decode(ticket.assignees[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.company = entities.decode(ticket.company[0]._.replace(/__b/g," ").replace(/__u/g,"-"));
          obj.requestor = "#{ticket.first__bname[0]._} #{ticket.last__bname[0]._}";
          obj.URL = "http://support.cusi.com/MRcgi/MRlogin.pl?DL=#{obj.ID}DA4"

          res.send "<#{obj.URL} |Issue #{obj.ID}> (#{obj.priority}, #{obj.status}) _#{obj.title}_"
          robot.brain.set('FootPrintRequestsServed', FootPrintRequestsServed+1)
        catch error
          console.log "There was an error"
      )
    )
