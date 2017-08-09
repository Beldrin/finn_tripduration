#Finn script: will find out walk/drive trip duration between apartments from finn.no and your custom address.
if (!require("XML")) install.packages("XML")
if (!require("RCurl")) install.packages("RCurl")
if (!require("ggmap")) install.packages("ggmap")
basefinncodeURL<-"https://www.finn.no/realestate/lettings/ad.html?finnkode"
#Basically finn.no have very good filtration options, and there is no point to code same functionality here.
#Just browse to finn.no and select location (like Frogner), price and other conditions to search.
#Finally, copy link from your search here
UrlFinn<-"https://www.finn.no/realestate/lettings/search.html?area_from=30&location=0.20061&location=1.20061.20531&price_to=11000"
#Here comes your target address, for example your office location
WorkAdress<-"Gaustadalleen 21, 0349 Oslo"
# scrape data
htmldata <- getURL(UrlFinn,.opts = list(ssl.verifypeer = FALSE) )
parsedhtml<- htmlParse(htmldata)
linklist <- xpathSApply(parsedhtml, "//a/@href")
linkdata<-data.frame(keyName=names(linklist), value=linklist, row.names=NULL)
linkdataSubset <- linkdata[grep("finnkode", linkdata$value), ]
linkdataSubset$value<-sub(".*=", "", linkdataSubset$value)
linkdataSubset$keyName <- NULL
finnID<-sequence(nrow(linkdataSubset))
lapply(finnID, FUN = function(x) {
  finncodeURL<-paste(basefinncodeURL,linkdataSubset$value[x], sep = "=")
  finncodeHTML<-getURL(finncodeURL,.opts = list(ssl.verifypeer = FALSE) )
  parsedfinncodehtml<- htmlParse(finncodeHTML)
  address <- lapply(parsedfinncodehtml['//*[@id="ad-start-link"]/div[2]/div[2]/div[2]/div/div/h2'],xmlValue)
  address<-unlist(address)
  #Change mode between walking, driving, bicycling, and transit for public transport.
  route_df <-route(address, WorkAdress, mode = "walking",
                   structure = "legs", output = "all",
                   alternatives = FALSE, messaging = FALSE, sensor = FALSE,
                   override_limit = FALSE)
  time<-route_df$routes[[1]]$legs[[1]]$duration$text
  print(paste("Walk trip time to", WorkAdress, "is", time, "for apartments on URL", finncodeURL, sep = " "))
#Optional check: you allowed run up to 2500 query to google maps API per day per IP. So you can check limits available
#routeQueryCheck()
})
