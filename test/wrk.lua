wrk.path  = "/flip-image/test?bucket=hello-demo-images-bucket&key=input/image-50.jpg"
wrk.method = "GET"

logfile = io.open("wrk.log", "w");

response = function(status, header, body)
     logfile:write("status:" .. status .. "\n");
     logfile:write("status:" .. status .. "\n" .. body .. "\n-------------------------------------------------\n");
end

done = function(summary, latency, requests)
     logfile:write("------------- END -------------\n")

     logfile.close();
end