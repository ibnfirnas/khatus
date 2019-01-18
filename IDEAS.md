Idea grab bag
-------------

- track devices:
    - alert when never before seen device is plugged-in
    - report history and trends on when and how-often each
      device/category is plugged-in, how-long it stays plaugged-in, etc.
- daemonize `khatus`, so we don't have to re-launch `X11` to re-launch `khatus`
- interoperate with other khatus nodes
    - prefix machine ID to each data source
      (What should that ID be? Hostname? Pub key?)
    - fetch remote data and process locally
    - what transport to use?
        - ssh + rsync + cache dumps per some interval?
    - `A` can setup self penetration testing, by setting up probe of `A` on `B`
      and fetching results from `B` to `A`
- offline mode - quick disable all network-using subsystems (sensors, monitors, etc)
- classify each sensor as either "local" or "remote" (what about `iwconfig`, et al?)
- store data with rrdtool
- some kind of personal calendar thing integration
- monitor tracking numbers (17track should be easiest to get started with)
- monitor password digests against known leaked password databases
- monitor stock prices
- monitor some item price(s) at some store(s) (Amazon, etc.)
    - https://docs.aws.amazon.com/AWSECommerceService/latest/DG/EX_RetrievingPriceInformation.html
    - https://docs.aws.amazon.com/AWSECommerceService/latest/DG/ReturningPrices.html
    - https://developer.amazonservices.com/
- monitor Amazon order status
    - https://developer.amazonservices.com/gp/mws/api.html?group=orders&section=orders
- monitor eBay order status
    - http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetOrders.html
- monitor eBay auctions (https://en.wikipedia.org/wiki/EBay_API)
- monitor PayPal (https://www.programmableweb.com/api/paypal)
- monitor bank account balance and transactions
    - https://communities.usaa.com/t5/Banking/Banking-via-API-Root/m-p/180789/highlight/true#M50758
    - https://plaid.com/
    - https://plaid.com/docs/api/
    - https://plaid.com/docs/api/#institution-overview
    - https://github.com/plaid
    - https://www.bignerdranch.com/blog/online-banking-apis/
- monitor/log road/traffic conditions
    - travel times for some route over a course of time
    - https://msdn.microsoft.com/en-us/library/hh441725
    - https://cloud.google.com/maps-platform/
    - https://cloud.google.com/maps-platform/routes/
    - https://developer.mapquest.com/documentation/traffic-api/
    - https://developer.here.com/api-explorer/rest/traffic/traffic-flow-bounding-box
- monitor news sources for patterns/substrings
    - http://developer.nytimes.com/
    - https://news.ycombinator.com/
    - https://lobste.rs/
    - https://www.undeadly.org/
    - http://openbsdnow.org/
    - https://lwn.net/
- monitor a git repository
    - General
        - total branches
        - age of last change per branch
        - change set sizes
    - GitHub
        - pull requests
        - issues
- monitor CI
    - Travis
    - Jenkins
- pull/push data from/to other monitoring systems (Nagios, Graphite, etc.)
- monitor file/directory age (can be used for email and other messaging systems)
- monitor mailboxes for particular patterns/substrings
- monitor IRC server(s)/channel(s) for particular patterns/substrings (use `ii`)
- monitor iptables log
    - auto-(un)block upon some threshold of violations
- monitor changes in an arbitrary web resource
    - deletions
    - insertions
    - delta = insertions - deletions
- monitor/log LAN/WAN configurations (address, router, subnet)
- monitor/log geolocation based on WAN IP address
- correlate iptables violations with network/geolocation
- monitor vulnerability databases
    - https://nvd.nist.gov/
    - https://vuldb.com/
    - http://cve.mitre.org/
- vacation planning optimization
    - I want to visit a set of places within some time period. Given the
      current set of prices, a set of constraints (I need to stay some amount
      of days at each, I must be in X at Y date, etc), which visiting dates for
      each are cheapest?
- browse https://www.programmableweb.com/ for some more ideas
- GC trick: instead of actually doing GC, do a dummy run of building a status
  bar at `BEGIN`, to fill-in the atimes for keys we need, then use the atimes
  keys to build a regular expression to accept messages only from keys we
  actually use

Many of the above will undoubtedly need non-standard-system dependencies
(languages, libraries, etc.), in which case - would they be better off as
separate projects/repos?

With all these ideas, it is starting to sound very noisy, but no worries - to
quickly and temporarily shut everything up - just kill `dunst` and or toggle
the status bar (`Alt` + `B` in `dwm`). For a permanent change - just don't
turn-on the unwanted monitors/sensors.
