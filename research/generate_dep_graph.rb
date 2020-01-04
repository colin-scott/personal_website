#!/usr/bin/ruby

require 'set' 
require 'optparse'
require 'fileutils'

options = {}
optparse = OptionParser.new("Usage: #{$0} [options] python_file") do |opts|
    options[:only_relevant] = false
    opts.on('-m', '--module-specific', "Only include python modules from this project") do |t|
        options[:only_relevant] = true
    end
end

optparse.parse!
if ARGV.empty?
    $stderr.puts optparse
    exit
end

system "wget http://www.tarind.com/py2depgraph.py"
system "wget http://www.tarind.com/depgraph2dot.py" 

input_file = ARGV[0]

system "python2.6 py2depgraph.py #{input_file} > depgraph"
system "python2.6 depgraph2dot.py < depgraph > depgraph.dot"

if options[:only_relevant]
    output = File.open("tmp.dot", "w")
    system %{find . -name "*py" > relevant.txt}
    relevant = Set.new
    
    File.foreach("relevant.txt") do |line|
        next if line =~ /__init__/
        $stderr.puts line
        line = line.gsub(/^.\//, "").gsub(/.py$/, "").gsub(/\//, "_").chomp
        $stderr.puts line
        relevant.add line
    end
    
    dot = "depgraph.dot"
    
    all_nodes = Set.new
    File.foreach(dot) do |line|
        next if line =~ /^node \[/ 
        next if line !~ /[^\s]+ \[/
        all_nodes.add line.chomp.split[0]
    end
    
    not_relevant = all_nodes - relevant
    
    def only_relevant_edge?(line, not_relevant)
       not_relevant.each do |node|
            return false if line =~ /#{node}/
       end
       return true
    end
    
    def relevant_node?(line, relevant)
        return true if line =~ /^node \[/ 
        relevant.each do |node|
            return true if line =~ /^#{node} \[/
        end
        return false
    end
    
    File.foreach(dot) do |line|
        next if line =~ /->/ and not only_relevant_edge?(line, not_relevant)
        next if line =~ /[^\s]+ \[/ and not relevant_node?(line, relevant)
        output.puts line
    end

    output.close
    FileUtils.mv("tmp.dot", "depgraph.dot")
end

system "dot -T png -o depgraph.png < depgraph.dot"
puts "Result in depgraph.png"
