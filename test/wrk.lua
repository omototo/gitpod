wrk.path  = "/flip-image/test?bucket=demo-images-imagemagick&key=input/pizza_image_L.jpg"
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