require 'watir-webdriver' 
require 'phantomjs'
require 'nokogiri'
require 'rest-client'
require 'csv'

#########################################################################################################
# 										Setting the Browser												#
#########################################################################################################

def start(url)
	br = Watir::Browser.new  :phantomjs
	br.goto(url)
	html = br.html
	br.close
	return html
end

def go_to(url)
	br = Watir::Browser.new  :phantomjs
	br.goto(url)
	sleep 5
	html = br.html
	br.close
	return html
end

#########################################################################################################
# 								Setting and Parsing the Main Page										#
#########################################################################################################

def iterate_main_page(location_string, loop_limit)

	mainresults = Array.new
	base_url = 'https://www.airbnb.com/s/'
	type = '?room_types%5B%5D=Entire+home%2Fapt'
    page_url = '&page='

	(1..loop_limit).each do |n|
		begin 
	    	puts "Processing Page #{n} out of #{loop_limit}"
	    	current_url = "#{base_url}#{location_string}#{type}#{page_url}#{n}"
	    	mainresults.push(*parse_main_xml(current_url, n))
	    rescue
			puts "This URL did not return results: #{current_url}"
		end	
    end
    puts "Done Processing Pages"
    return mainresults
end

def parse_main_xml(url, pg)
	
	listingdb = Array.new

	tree = Nokogiri::HTML(start(url))
	listings = tree.xpath('//div[@class="listing"]')

	n=1
	listings.each do |listing|
			dat = {Baseurl: url,
					Lat: listing.attribute('data-lat').value,
		    		Long: listing.attribute('data-lng').value,
		    		Title: listing.attribute('data-name').value,
		    		ListingID: listing.attribute('data-id').value,
		    		UserID: listing.attribute('data-user').value,
		    		Price: "#{listing.xpath('div//span[@class="h3 text-contrast price-amount"]/text()')}",
		    		PageCounter: n,
		    		OverallCounter: n * pg,
		    		PageNumber: pg}
		    
		    listingdb << dat

		    n += 1
	end

	return listingdb

end

#########################################################################################################
# 										Detailed results 												#
#########################################################################################################

def iterate_detail(mainresults)

	finalresults = Array.new
	counter = 0
	baseURL = 'https://www.airbnb.com/rooms/' 
	days = set_date_URL()


	mainresults.each do |listing|
		counter +=1
		puts "Processing Listing #{counter} out of #{mainresults.length}"
		currentURL = "#{baseURL}#{listing[:ListingID]}#{days}"

		tree = get_tree(currentURL)

		detailresults = collect_detail(tree, listing[:ListingID], currentURL)

		newlisting = listing.merge(detailresults)

		finalresults << newlisting

	end

	return finalresults


end

def set_date_URL()

	d =  Time.new


	current_date = d.day
	current_month = d.mon
	current_year = d.year

	tomorrow = d.day + 1

	dateURL = "?checkin=#{current_month}%2F#{current_date}%2F#{current_year}&checkout=#{current_month}%2F#{tomorrow}%2F#{current_year}"

	return dateURL

end

def get_tree(url)

	tree = Nokogiri::HTML(go_to(url))

end

def collect_detail(treeObject, listingID, detailURL)
    results = {Listing_URL: detailURL,
    			 AboutListing: 'Not Found', 
	             HostName: 'Not Found',
	             CurrentlyBooked: 0,
	             RespRate: 'Not Found',
	             RespTime: 'Not Found',
	             MemberDate: 'Not Found',
	             R_acc: 'Not Found',
	             R_comm: 'Not Found',
	             R_clean: 'Not Found',
	             R_loc: 'Not Found',
	             R_CI: 'Not Found',
	             R_val: 'Not Found',
	             P_ExtraPeople: 'Not Found',
	             P_Cleaning: 'Not Found',
	             P_Deposit: 'Not Found',
	             P_Weekly: 'Not Found',
	             P_Monthly: 'Not Found',
	             Cancellation: 'Not Found',
	             A_Kitchen: 0,
	             A_TV: 0, 
	             A_Essentials: 0,
	             A_Shampoo: 0,
	             A_Heat: 0,
	             A_AC: 0,
	             A_Washer: 0,
	             A_Dryer: 0,
	             A_Parking: 0,
	             A_Internet: 0,
	             A_CableTV: 0,
	             A_Breakfast:  0,
	             A_Pets: 0,
	             A_FamilyFriendly: 0,
	             A_Events: 0,
	             A_Smoking: 0,
	             A_Wheelchair: 0,
	             A_Elevator: 0,
	             A_Fireplace: 0,
	             A_Intercom: 0,
	             A_Doorman: 0, 
	             A_Pool: 0,
	             A_HotTub: 0,
	             A_Gym: 0,
	             A_SmokeDetector: 0,
	             A_CarbonMonoxDetector: 0,
	             A_FirstAidKit: 0,
	             A_SafetyCard: 0,
	             A_FireExt: 0, 
	             S_RoomType: 'Not Found',
	             S_PropType: 'Not Found',
	             S_Accomodates: 'Not Found',
	             S_Bedrooms: 'Not Found',
	             S_Bathrooms: 'Not Found',
	             S_NumBeds: 'Not Found',
	             S_CheckIn: 'Not Found',
	             S_Checkout: 'Not Found'
	             }

    results[:AboutListing] = getAboutListing(treeObject, listingID)
    results[:HostName] = getHostName(treeObject, listingID)
    results[:CurrentlyBooked] = booking(treeObject, listingID)
    results[:RespRate], results[:RespTime] = getHostResponse(treeObject, listingID)
    results[:MemberDate] = getMemberDate(treeObject, listingID)
    #accuracy, communication, cleanliness, location, checkin, value
    results[:R_acc], results[:R_comm], results[:R_clean], results[:R_loc], results[:R_CI], results[:R_val] = getStars(treeObject, listingID)
    #price
    pricedata = getPriceInfo(treeObject, listingID)
    results[:P_ExtraPeople] = pricedata[:ExtraPeople]
    results[:P_Cleaning] = pricedata[:CleaningFee]
    results[:P_Deposit] = pricedata[:SecurityDeposit]
    results[:P_Weekly] = pricedata[:WeeklyPrice]
    results[:P_Monthly] = pricedata[:MonthlyPrice] 
    results[:Cancellation] = pricedata[:Cancellation]
    #Amenities
    am = getAmenities(treeObject, listingID)
    results[:A_Kitchen] = am['Kitchen']
    results[:A_Internet] = am['Internet']
    results[:A_TV] = am['TV'] 
    results[:A_Essentials] = am['Essentials' ]
    results[:A_Shampoo] = am['Shampoo'] 
    results[:A_Heat] = am['Heating'] 
    results[:A_AC] = am['Air Conditioning'] 
    results[:A_Washer] = am['Washer'] 
    results[:A_Dryer] = am['Dryer'] 
    results[:A_Parking] = am['Free Parking on Premises'] 
    results[:A_Internet] = am['Wireless Internet'] 
    results[:A_CableTV] = am['Cable TV' ]
    results[:A_Breakfast] = am['Breakfast'] 
    results[:A_Pets] = am['Pets Allowed'] 
    results[:A_FamilyFriendly] = am['Family/Kid Friendly'] 
    results[:A_Events] = am['Suitable for Events']
    results[:A_Smoking] = am['Smoking Allowed'] 
    results[:A_Wheelchair] = am['Wheelchair Accessible'] 
    results[:A_Elevator] = am['Elevator in Building'] 
    results[:A_Fireplace] = am['Indoor Fireplace' ]
    results[:A_Intercom] = am['Buzzer/Wireless Intercom'] 
    results[:A_Doorman] = am['Doorman'] 
    results[:A_Pool] = am['Pool'] 
    results[:A_HotTub] = am['Hot Tub'] 
    results[:A_Gym] = am['Gym']
    results[:A_SmokeDetector] = am['Smoke Detector'] 
    results[:A_CarbonMonoxDetector] = am['Carbon Monoxide Detector'] 
    results[:A_FirstAidKit] = am['First Aid Kit' ]
    results[:A_SafetyCard] = am['Safety Card'] 
    results[:A_FireExt] = am['Fire Extinguisher'] 

    space = getSpaceInfo(treeObject, listingID)
    results[:S_RoomType] = space[:RoomType]
    results[:S_PropType] = space[:PropType]
    results[:S_Accomodates] = space[:Accommodates]
    results[:S_Bedrooms] = space[:Bedrooms]
    results[:S_Bathrooms] = space[:Bathrooms] 
    results[:S_NumBeds] = space[:NumBeds]
    results[:S_CheckIn] = space[:CheckIn]
    results[:S_Checkout] = space[:CheckOut]

    return results
end

def getAboutListing(tree, listingID)
    aboutlisting = 'Not Found'
    begin 
    	element = tree.xpath('//*[@id="details-column"]/div/p[1]/text()')
    	return element.to_s
    rescue
    	puts "Unable to parse about section for lisitng id: #{listingID}"
    	return aboutlisting
    end
end

def getHostName(tree, listingID)
	hostname = 'Not Found'
    begin 
    	host_name = tree.xpath('//*[@id="summary"]//a[@href="#host-profile"]/text()')
    	return host_name.text  
	rescue 
		puts "Unable to parse host name for listing id: #{listingID}"
		return hostname
	end  
end

def booking(tree, listingID)
	begin 
		something = tree.xpath('//div[@class="js-book-it-status"]//p/text()').inner_text
		if something.include? "Those dates are not available"
			return 1
		else
			return 0
		end
	rescue
		puts "Unable to parse booking avalibility for listing id: #{listingID}"
		return 0 
	end
end

def getHostResponse(tree, listingID)
    response_rate = 'Not Found'
    response_time = 'Not Found'
    begin
        response_rate = tree.xpath('//*[@id="host-profile"]//div[@class="col-md-6"][2]/strong/text()')
        response_time = tree.xpath('//*[@id="host-profile"]//div[@class="col-md-6"][2]/div/strong/text()')
        return response_rate.text, response_time.text         
    rescue
        puts "Unable to parse response time for listing id: #{listingID}"
        return response_rate, response_time    
	end
end

def getMemberDate(tree, listingID)
    membership_date = 'Not Found'    
    begin
        membership_date = tree.xpath('//*[@id="host-profile"]//div[@class="col-md-6"]/div[2]/text()')
        membership_date = membership_date.to_s.strip.sub! 'Member since ', ''
        return membership_date
    rescue
        puts "Unable to parse membership date for listing id: #{listingID}" 
        return membership_date.to_s
    end
end

def getStars(tree, listingID)
    accuracy = 'Not Found'
    communication = 'Not Found'
    cleanliness = 'Not Found'
    location = 'Not Found'
    checkin = 'Not Found'
    value = 'Not Found' 
    begin
        accuracy = singlestar(1, tree)
        communication = singlestar(2, tree)
        cleanliness = singlestar(3, tree)
        location = singlestar(4, tree)
        checkin = singlestar(5, tree)
        value = singlestar(6, tree)
        return accuracy, communication, cleanliness, location, checkin, value
    rescue
        puts "Unable to parse stars listing id: #{listingID}" 
        return accuracy, communication, cleanliness, location, checkin, value
    end
end

def singlestar(index, tree)
	stars = 0
    (0..5).each do |star|
	    if tree.at_xpath("(//div[@class='review-wrapper']//div[@class='row']//*[@class='star-rating'])[#{index}]//*[@class='icon-star icon icon-beach icon-star-small'][#{star}]")
			stars += 1
		end
		if tree.at_xpath("(//div[@class='review-wrapper']//div[@class='row']//*[@class='star-rating'])[#{index}]//*[@class='icon-star-half icon icon-beach icon-star-small'][#{star}]")
			stars += 0.5
		end
	end
	if stars == 0
		stars = 'Not Found'
	end
    return stars.to_i
end


def getPriceInfo(tree, listingID)     

    dat= Hash.new
    dat = {ExtraPeople: 'Not Found', 
    		CleaningFee: 'Not Found',
    		SecurityDeposit: 'Not Found',
    		WeeklyPrice: 'Not Found',
    		MonthlyPrice: 'Not Found',
    		Cancellation: 'Not Found'}
    
    begin
        elements = tree.xpath('//*[@class="___iso-html___p3about_this_listingbundlejs airbnb-mystique"]')
        prices = elements.xpath('//*[text()= "Prices"]/parent::*/parent::*/following-sibling::*')

        extrapeople = prices.xpath('//*[text()= "Extra people:"]/following-sibling::*[2]')
        if extrapeople.text.length > 0
        	dat[:ExtraPeople] = extrapeople.text
        end

        cleaningfee = prices.xpath('//*[text()= "Cleaning Fee:"]/following-sibling::*[2]')
        if cleaningfee.text.length > 0
        	dat[:CleaningFee] = cleaningfee.text
        end

        securitydeposit = prices.xpath('//*[text()= "Security Deposit:"]/following-sibling::*[2]')
        if securitydeposit.text.length > 0
        	dat[:SecurityDeposit] = securitydeposit.text
        end

        weeklyprice = prices.xpath('//*[text()= "Weekly Price:"]/following-sibling::*[2]')
        if weeklyprice.text.length > 0
        	weeklyprice = weeklyprice.text.gsub(' /week', '')
        	dat[:WeeklyPrice] = weeklyprice
        end

        monthlyprice = prices.xpath('//*[text()= "Monthly Price:"]/following-sibling::*[2]')
        if monthlyprice.text.length > 0
        	monthlyprice = monthlyprice.text.gsub(' /month', '')
        	dat[:MonthlyPrice] = monthlyprice
		end

        cancellation = prices.xpath('//*[text()= "Cancellation:"]/following-sibling::*[2]')
        if cancellation.text.length > 0
        	dat[:Cancellation] = cancellation.text
        end

        return dat
    rescue
        puts "Error in getting Space Elements for listing iD: #{listingID}" 
        return dat
    end
end

def getAmenitiesList(tree, listingID)

    amenities = Array.new
    
    begin
        elements = tree.xpath('//*[@class="___iso-html___p3about_this_listingbundlejs airbnb-mystique"]')
        
        amenitylist = elements.xpath('(//*[text()= "Amenities"]/parent::*/parent::*//div[@class="col-sm-6"])[3 or 4]')

        amenitylist.xpath('.//span/strong/text()').each do |amenity|
        	amenities << amenity.text
        end 

        return amenities    
    rescue
        print "Error in getting amenities for listing iD: #{listingID}" 
        return amenities
    end
end

def getAmenities(tree, listingID)    
       
    dat = {"Kitchen" => 0, 
    		"Internet" => 0, 
    		"TV" => 0, 
    		"Essentials" => 0,
           	"Shampoo" => 0, 
           	"Heating" => 0, 
           	"Air Conditioning" => 0, 
           	"Washer" => 0, 
           	"Dryer" => 0, 
           	"Free Parking on Premises" => 0, 
           	"Wireless Internet" => 0, 
           	"Cable TV" => 0,
           	"Breakfast" => 0, 
           	"Pets Allowed" => 0, 
           	"Family/Kid Friendly" => 0, 
           	"Suitable for Events" => 0,
           	"Smoking Allowed" => 0, 
           	"Wheelchair Accessible" => 0, 
           	"Elevator in Building" => 0, 
           	"Indoor Fireplace" => 0,
           	"Buzzer/Wireless Intercom" => 0, 
           	"Doorman" => 0, 
          	"Pool" => 0, 
          	"Hot Tub" => 0, 
          	"Gym" => 0,
          	"Smoke Detector" => 0, 
           	"Carbon Monoxide Detector" => 0, 
           	"First Aid Kit" => 0,
           	"Safety Card" => 0, 
           	"Fire Extinguisher" => 0}    
             
    amenities = getAmenitiesList(tree, listingID)

    amenities.each do |amenity|
    	dat[amenity] = 1
    end
    
    return dat    
end

def getSpaceInfo(tree, listingID) 
    #Initialize Values
    dat = {RoomType: 'Not Found',
    		PropType: 'Not Found', 
    		Accommodates: 'Not Found', 
           	Bedrooms: 'Not Found', 
           	Bathrooms: 'Not Found',
           	NumBeds: 'Not Found', 
           	CheckIn: 'Not Found', 
           	CheckOut: 'Not Found'}    
    
    begin
    	elements = tree.xpath('//*[@class="___iso-html___p3about_this_listingbundlejs airbnb-mystique"]')
    	thespacelist = elements.xpath('//*[text()= "The Space"]/parent::*/parent::*/following-sibling::*')

    	roomtype = thespacelist.xpath('//*[text()= "Room type:"]/following-sibling::*[2]')
        if roomtype.text.length > 0
        	dat[:RoomType] = roomtype.text
        end

    	proptype = thespacelist.xpath('//*[text()= "Property type:"]/following-sibling::*[2]')
        if proptype.text.length > 0
        	dat[:PropType] = proptype.text
        end

        accommodates = thespacelist.xpath('//*[text()= "Accommodates:"]/following-sibling::*[2]')
        if accommodates.text.length > 0
        	dat[:Accommodates] = accommodates.text

        end

        bedrooms = thespacelist.xpath('//*[text()= "Bedrooms:"]/following-sibling::*[2]')
        if bedrooms.text.length > 0
        	dat[:Bedrooms] = bedrooms.text
        end

        bathrooms = thespacelist.xpath('//*[text()= "Bathrooms:"]/following-sibling::*[2]')
        if bathrooms.text.length > 0
        	dat[:Bathrooms] = bathrooms.text
        end

        numbeds = thespacelist.xpath('//*[text()= "Beds:"]/following-sibling::*[2]')
        if numbeds.text.length > 0
        	dat[:NumBeds] = numbeds.text
        end

        checkin = thespacelist.xpath('//*[text()= "Check In:"]/following-sibling::*[2]')
        if checkin.text.length > 0
        	dat[:CheckIn] = checkin.text
        end

        checkout = thespacelist.xpath('//*[text()= "Check Out:"]/following-sibling::*[2]')
        if checkout.text.length > 0
        	dat[:CheckOut] = checkout.text
        end

        return dat
    rescue
        puts "Error in getting Space Elements for listing iD: #{listingID}"
        return dat
    end
end

#########################################################################################################
# 										Create CSV File 												#
#########################################################################################################

def createCSV(detailedresults)


	keys = detailedresults.first.keys

	CSV.open("/volumes/ALEX/airbnb.csv", "wb") do |csv|
	  csv << keys
	  
	  detailedresults.each do |listing|
	  	attributes = listing.values
	  	csv << attributes
	  end

	end
end

#########################################################################################################
# 										Running The Code												#
#########################################################################################################

mainresults = iterate_main_page('South-lake-tahoe--CA', 1)
detailedresults = iterate_detail(mainresults)
createCSV(detailedresults)





