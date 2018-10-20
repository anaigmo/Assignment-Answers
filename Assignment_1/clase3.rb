require 'net/http'
require './gene_class.rb'
#require './seedstock_class.rb'
#require './cross_class.rb'

def fetch(uri_str)  # this "fetch" routine does some basic error-handling.  

  address = URI(uri_str)  # create a "URI" object (Uniform Resource Identifier: https://en.wikipedia.org/wiki/Uniform_Resource_Identifier)
  response = Net::HTTP.get_response(address)  # use the Net::HTTP object "get_response" method
                                               # to call that address

  case response   # the "case" block allows you to test various conditions... it is like an "if", but cleaner!
    when Net::HTTPSuccess then  # when response is of type Net::HTTPSuccess
      # successful retrieval of web page
      return response  # return that response object
    else
      raise Exception, "Something went wrong... the call to #{uri_str} failed; type #{response.class}"
      # note - if you want to learn more about Exceptions, and error-handling
      # read this page:  http://rubylearning.com/satishtalim/ruby_exceptions.html  
      # you can capture the Exception and do something useful with it!
      response = false
      return response  # now we are returning False
  end 
end


class AnotatedGene < Gene 
  
  attr_accessor :dna_seq  
  attr_accessor :prot_seq
  
  def initialize (params = {})
    super(params)
  end
  
  def dna_sequence(seq)
		if seq.is_a?(String)
			dna_seq = seq
		end
	end
  
  def prot_sequence(seq)
		if seq.is_a?(String)
			prot_seq_seq = seq
		end
	end
  
end


















list_genes = create_genes()
#list_seedstock = create_seedstock(list_genes)
#list_crosses = create_cross(list_seedstock)

list_genes.each_key do |keyID|
	puts list_genes[keyID].ID
	res = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{keyID}");
	
	if res  # res is either the response object, or False, so you can test it with 'if'
		body = res.body  # get the "body" of the response
		puts body
	end
end 


