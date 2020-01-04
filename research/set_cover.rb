#!/usr/bin/ruby1.9 -w

# Todo: figure out how to use IP objects so I don't have to take the brute approach to updating

# correct usage check
if ARGV.size < 1
  print("Usage: " + $0 + " [input file]\n")
  exit
end

require '~/Networks/Scripts/classes+modules/pqueue.rb'
require '~/Networks/Scripts/classes+modules/VP.rb'
require 'set'

input = File.open("#{ARGV[0]}")

#==========================================#
#           Method Definitions             #
#==========================================#
def filter_off(ip, line, input, vp_hash)
	process_line(ip, find_elem(line, 3), find_elem(line, 2), vp_hash)
  # while there is still data, and while the IP of next
  # is the same as this IP, yield statement
  while nex = input.gets and find_elem(nex).eql?(ip)
    #yield the VP (index 3) and IP (index 1)
		process_line(ip, find_elem(nex, 3), find_elem(nex, 2), vp_hash)
  end
  #return the line that contains the first different prefix
  nex
end

# Data is in the form:
# [prefix] [IP address] [score] [VP]
# By default, finds the IP address
def find_elem(line, index = 1)
  delim = line.chomp.split(' ')
  prefix = delim[index]
end

def process_line(ip, vp_name, score, vp_hash)

	#use the hash to ensure uniqueness
	vp_hash[vp_name] = VP.new(vp_name) unless vp_hash.has_key?(vp_name)

	#put in ip to the vp's set
	curr_vp = vp_hash.fetch(vp_name)
	curr_vp.add(ip, score)
	#I know the data is sorted by prefix, so I can just add vp to the current IP
	#since line must belong to the same IP address as the previous line
	#ip.add_vp(curr_vp)

end

def print_output(vp_q, ip_count, ip_set)
	#print header
	if(ARGV[0].include?('.'))
		puts "--------- Prefix #{ARGV[0]} --------"
	else
		puts "----------- AS #{ARGV[0]} -----------"
	end

	puts "---# of IP addresses : #{ip_count}---"

	coverage = 0.0
	vp_choices = []

	while coverage < 100.0
		# choose a VP
		chosen = vp_q.pop
		vp_choices << chosen

		#debug
		#print "#{chosen.to_s} contains: "
		chosen.get_set.each do |ip_2_delete|
		#	print ip_2_delete, ", "
			ip_set.delete(ip_2_delete)
		end
	
		# Iterate over all remaining VPs. For each VP, remove all of the IPs
		# covered by chosen
		vp_q.to_a.each do |vp_elem|
			chosen.get_set.each do |ip_2_delete|
				vp_elem.remove(ip_2_delete) if vp_elem.contains?(ip_2_delete)
			end
		end		
		
		#It is really annoying that I have to do this, but I need to pop out all of
		#items in the priority queue and then put them back in again so the queue 
		#is properly updated
		buffer = []
		vp_q.each_pop do |vp|
			buffer << vp
		end
	
		buffer.each do |vp|
			vp_q.push(vp)
		end
		
	
		#update coverage
		coverage = 100 - (ip_set.size * 100.0 / ip_count)
	
	
		#print output
		#format is [# of chosen VPs] {[Chosen VPs]} [coverage]
		print "#{vp_choices.size} {"
		print	vp_choices[0].to_s
		1.upto(vp_choices.size - 1) do |index|
			print "::#{vp_choices[index].to_s}"
		end
		print "} #{coverage} % \n"
	end
	
	#Print the rest of the in range VPs in random order
	while vp_q.size > 0
		# choose a VP
		chosen = vp_q.pop
		vp_choices << chosen
		print "#{vp_choices.size} {"
		print	vp_choices[0].to_s
		
		1.upto(vp_choices.size - 1) do |index|
			print "::#{vp_choices[index].to_s}"
		end
		print "} #{coverage} % \n"
	end
	puts
end

#==========================================#
#           Begin building sets            #
#==========================================#

# Priority Queues take VP objects as elements
vp_q = PQueue.new(proc do |vp1,vp2|
										if(vp1.count != vp2.count)
											vp1.count > vp2.count 
										else
											vp1.score_total > vp2.score_total
										end
end)

#Set up a hash for VPs to ensure uniqueness
#keys are strings (vp names) and values are VP objects 
vp_hash = {}

#for debugging purposes
ip_set = Set.new

#get first line
line = input.gets
#iterate through file
#takes advantage of the fact that the data is sorted according to prefix / AS
#while(line) just ensures that we don't run past the end of the file.
#the File I/O is carried out by filter_off

#perhaps a more general implementation of this wouldn't assume that data is sorted
#in that case, just use two hashes instead of one.
ip_count = 0
while(line)
	ip_count += 1
	#create an IP object for each IP	
	ip = find_elem(line)
	ip_set.add(ip)
	
	#line gets assigned to the first line of the next block of IP addresses.
	#Remember, assigment happens last, so the parameter is the result from the most recent iteration
  line = filter_off(ip, line, input, vp_hash)  

end

#Now gather the VP's and their corresponding IP sets and insert them into the priority queue.
vp_hash.each do |key, value|
	vp_q.push(value)
end

=begin
# run a little test
vp_hash.each do |key, elem|
	puts elem
	puts "Contains These IPs:"
	puts
	elem.get_set.each do |iPP|

		puts iPP
	end
end
=end

#==========================================#
#               Begin Output               #
#==========================================#
# Output:
# for each prefix, you'd want the # of addresses, the ordering on vantage points,
# and the coverage you get from the first k vantage points.
print_output(vp_q, ip_count, ip_set) 
