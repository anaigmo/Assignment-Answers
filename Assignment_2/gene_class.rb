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
    @proteins = []
    @kegg_path = {}
    @GO_term = {}
    
    # # Get the id of the protein with it interacts with
    # intact = []
    # unless (!data["dr"]["IntAct"])
    #   data["dr"]["IntAct"].each do |entry|
    #     intact.push(entry[0])
    #   end
    # end
    
    data["accessions"].each do |entry|
      @proteins.push(entry) unless (@proteins.include?(entry))  # unless it interacts with itself
    end
    
    kegg_id = @gene_ID.upcase
    paths = []
    kegg_pathways[0].each do |line|  # In the list of all the pathways in A. thaliana, look for the ones in which the gene is involved
      elements = line.split("\t")
      paths.push(elements[1]) if (elements[0] == "ath:#{kegg_id}")
    end

    paths.each do |path|
      path_num = path.split(//).last(5).join
      if kegg_pathways[1].key?("path:map#{path_num}")
        @kegg_path[path] = kegg_pathways[1]["path:map#{path_num}"]
      end
    end

   # Take all the entries of GO in the Togo search
    if (data["dr"]["GO"])
      data["dr"]["GO"].each do |entry|
          @GO_term[entry[0]] = entry[1].split(":")[1] if (entry[1][0] == "P")
      end
    else
      @GO_term = "No anotated"
    end

  end
  
end