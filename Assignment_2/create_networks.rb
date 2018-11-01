require 'net/http'
require 'json' 
require './gene_class.rb'

## ----- FUNCTIONS ----- ##

def create_genes(in_file, kegg_pathways)
  # This function creates instances of the class Gene from the lines in ArabidopsisSubNetwork_GeneList.txt
  
  first_line = true
  list_genes = {}
  
  return false unless (File.file?(in_file))  # Check that the file exists
  
  print "Looking for proteins associated to genes..."
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      first_line = false
    
    else
      line = line.chomp
      new_gene = Gene.new(:gene_ID => line)  # Create the object
      new_gene.get_attributes(kegg_pathways)
      list_genes[line] = new_gene  # Store the object in a file, with kei the variable ID
    end
  end
  
  puts "Done"
  return list_genes
  
end


def access_kegg(species)
    address = URI("http://rest.kegg.jp/link/pathway/#{species}")
    response = Net::HTTP.get_response(address)
    data = response.body.split("\n")
    return data
end
  
  
def access_tab25(id)
    address = URI("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{id}?format=tab25")
    response = Net::HTTP.get_response(address)
    data = response.body.split("\n")
    return data
end





## ----- MAIN ----- ##

kegg_pathways = access_kegg("ath")
genes = create_genes("Arabidopsis10.txt", kegg_pathways)



conections = {}

genes.each_key do |key|
  
  genes[key].proteins.each do |prot|
    tab25 = access_tab25(prot)
    
    if (tab25)
      interactions = []
      
      tab25.each do |int|
        column = int.split("\t")
        
        if (column[9] =~ /taxid:3702/ && column[10] =~ /taxid:3702/)  # Falta control de PSI_MI
          ids = []
          ids.push(column[0].split(":")[1])
          ids.push(column[1].split(":")[1])
          
          if (ids[0] != prot)
            interactions.push(ids[0])
          elsif (ids[1] != prot)
            interactions.push(ids[1])
          end
          
        end  
      end
      
      if (interactions != [])  # Find out if the vector is not empty
        
        conections[prot] = interactions
        
      end
    end
  end
end

puts conections












