wrk.path  = "/flip-image/test?bucket=hello-demo-images-bucket&key=input/image-50.jpg"
wrk.method = "GET"

logfile = io.open("wrk.log", "w");
local cnt = 0;

response = function(status, header, body)
     logfile:write("status:" .. status .. "\n");
     cnt = cnt + 1;
     logfile:write("status:" .. status .. "\n" .. body .. "\n-------------------------------------------------\n");
end

done = function(summary, latency, requests)
     logfile:write("------------- SUMMARY -------------\n")
     print("Response count: ", cnt)
     logfile.close();
end