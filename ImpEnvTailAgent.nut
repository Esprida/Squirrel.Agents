// Agent Code
/*This code reports the temperature, humidity, light status and air pressure 
back to the LiveControl server. */

/*Please refer to the electric imp agents codes README file to better understand 
the script and how to run it.
*/


local lastReading = {};
lastReading.pressure <- 1013.25;
lastReading.temp <- 22;
lastReading.day <- true;
lastReading.humid <- 0;

// Add a function to post data from the device to your stream

function manageReading(reading) {
    // Note: reading is the data passed from the device, ie.
    // a Squirrel table with the key 'temp'
    //This is the first part of the script: Registering the sensor as root asset. Only once
   // Define a table with the JASON registration info 
    local Registeration_Data = {
    apiKey = "271c0e74-90ca-4598-800b-4e0339de9d55", //THE API HAS TO EXIST/GENERATED FROM THE SERVER, DEVELOPER SECTION
    srNo = reading.id, //it gets the device serial number from the "reading"
    assetName ="electric imp Env Tail",
    assetTypeCode = "embedded-sensor",
    timeZoneId = "America/Toronto"
    }
    local reg_body = http.jsonencode(Registeration_Data);
    server.log(reg_body);

    # POST the registration data with JSON 

    local reg_url = "http://EXAMPLE.esprida.com/agentapi/register" //THIS IS NOT A WORKING URL, IT'S AN EXAMPLE ONLY
    local reg_headers = {"content-type": "application/json"} #This is general/default
    
    local reg_request = http.post(reg_url, reg_headers, reg_body);
    local reg_response = reg_request.sendsync();
    server.log(reg_response.statuscode);
    server.log(reg_response.body);
    //Get the assetLogin from the register's post http response and use it for the assetMetric 
    //To do that, we need to decode the json of the http response and get the assetLogin
    //The assetLogin is a "result" object that is inside the response object
    local assetLogin = http.jsondecode(reg_response.body).result.assetLogin;
    server.log(assetLogin);
    //We will need to encode to use it with the assetMetric method.
    local EncodedAssetLogin = assetLogin
    


    //############################################################################
  
    // This is the second part: Sending the temperature periodically   
    // Define a table with the JASON info

        local AssetMetric_Data =  [
        {
        metricCode="Temperature",
        values=[
            {
                    metricValue= reading.temp,
                    detectionTime= currentISO8601()
            }
            ]},
        {
        metricCode="Humidity",
            values=[
            {
                    metricValue= reading.humid,
                    detectionTime= currentISO8601()
            }
            ]},
        {
        metricCode="Air_Pressure",
        values=[
            {
                    metricValue= reading.pressure,
                    detectionTime= currentISO8601()
            }
            ]},
        {
        metricCode="Light.Day/Night",
        values=[
            {
                    metricValue= reading.day,
                    detectionTime= currentISO8601()
            }
            ]}
        
        ]   

         // encode data into JSON and log
        local body = http.jsonencode(AssetMetric_Data);
        server.log(body);
 
        local url = "http://EXAMPLE.esprida.com/agentapi/assetmetrics"; //THIS IS NOT A WORKING URL, IT'S AN EXAMPLE ONLY
        local headers = {"Content-Type": "application/json", "Authorization" : "Basic " + http.base64encode(assetLogin + ":" + "")};
    
        local request = http.post(url, headers, body);
        local response = request.sendsync();
        server.log(response.statuscode);
}
//This function converts the timestamp sent with the temerpature in UTC to ISO8601
function currentISO8601(){
    local dt = date().year + "-"
    local timeArray = [(date().month+1), date().day, date().hour, date().min, date().sec]
    foreach(idx,val in timeArray){
       if (val < 10 ) val = "0"+val
       switch (idx){
            case 0:
                dt = dt+ val +"-" 
                break
            case 1:
                 dt = dt+ val +"T"
                 break
            case 2: 
                 dt = dt+ val +":"
                 break
            case 3: 
                 dt = dt+ (val) +":" 
                 break     
            case 4:
                dt = dt+ val +"Z"
                break     
                 } 
}
    return dt;


    }



// Register the function to handle data messages from the device
device.on("reading", manageReading);
