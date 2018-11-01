require 'net/http'
require 'json'  

class Gene
  
  attr_accessor :gene_ID  
  attr_accessor :prot_name
  attr_accessor :proteins
  attr_accessor :kegg_path
  attr_accessor :GO_term
  
  def initialize (params = {})
    @gene_ID = params.fetch(:gene_ID, 'unknown gene')
    abort("ERROR: Wrong gene ID, #{gene_ID}") unless @gene_ID =~ /A[Tt]\d[Gg]\d\d\d\d\d/ 
  end
  
  def access_togo(id, database)
    address = URI("http://togows.dbcls.jp/entry/#{database}/#{id}.json")
    response = Net::HTTP.get_response(address)  
    data = JSON.parse(response.body)
    return data[0]
  end
  
  
  
  def get_attributes(kegg_pathways)
    data = access_togo(@gene_ID, "uniprot")
    @prot_name = data["entry_id"]
    @proteins = data["accessions"]
    @kegg_path = {}
    @GO_term = {}
    
    data["dr"]["KEGG"].each do |entry|
      if entry[0].match(/ath/)  # Take only the IDs from Arabidopsis thaliana
        
        paths = []
        kegg_pathways.each do |line|  # In the list of all the pathways in A. thaliana, look for the ones in which the gene is involved
          elements = line.split("\t")
          paths.push(elements[1]) if (elements[0] == entry[0]) 
        end
        
        @kegg_path[entry[0]] = paths
        
      end
      
    end
    
    # Take all the entries of GO in the Togo search
    if (data["dr"]["GO"])
      data["dr"]["GO"].each do |entry|
        @GO_term[entry[0]] = entry[1]
      end
    else
      @GO_term = "Unknown"
    end
    
  end
  
end