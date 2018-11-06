require 'net/http'
require 'json'
require './gene_class.rb'
require './interaction_network_class.rb'

## ----- FUNCTIONS ----- ##

def create_genes(in_file, kegg_pathways)
  # This function creates instances of the class Gene from the lines in ArabidopsisSubNetwork_GeneList.txt
  
  list_genes = {}
  
  return false unless (File.file?(in_file))  # Check that the file exists
  
  print "Looking for proteins associated to genes... "
  
  File.open(in_file, "r").each do |line|
    
    line = line.chomp
    new_gene = Gene.new(:gene_ID => line)  # Create the object
    new_gene.get_attributes(kegg_pathways)
    list_genes[line] = new_gene  # Store the object in a file, with key the variable ID
    
  end
  
  puts "Done"
  return list_genes

end



def access_kegg(species)
  
  address = URI("http://rest.kegg.jp/link/pathway/#{species}")
  response = Net::HTTP.get_response(address)
  paths = response.body.split("\n")

  address = URI("http://rest.kegg.jp/find/pathway/#{species}")
  response = Net::HTTP.get_response(address)
  data = response.body.split("\n")

  names = {}
  data.each do |line|
    elements = line.chomp.split("\t")
    names[elements[0]] = elements[1]
  end

  return [paths, names]

end
  
  
  
def access_tab25(id)
  
    address = URI("http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/query/#{id}?format=tab25")
    response = Net::HTTP.get_response(address)
    data = response.body.split("\n")
    return data

end



def get_connections(prot)

  tab25 = access_tab25(prot)
  
  interactions = []
  if (tab25)
     
    tab25.each do |int|
      column = int.split("\t")
          
      if (column[9]=~/taxid:3702/ && column[10]=~/taxid:3702/ && (column[6]=~/MI:(0006|0007|0047|0055|0065|0084|0096|0402|0676|1356)/))  # Falta control de PSI_MI
        ids = []
        ids.push(column[0].split(":")[1])
        ids.push(column[1].split(":")[1])
            
        if (ids[0] != prot && !interactions.include?(ids[0]))
          interactions.push(ids[0])
        elsif (ids[1] != prot && !interactions.include?(ids[1]))
          interactions.push(ids[1])
        end
            
      end  
    end          
  end
      
  return interactions  # Find out if the vector is not empty

end



def get_proteins(genes)
  
  proteins = {}

  genes.each_key do |key|
    
    genes[key].proteins.each do |prot|
      proteins[prot] = genes[key]
    end
  
  end

  return proteins

end



def create_networks(genes, proteins)
  print "Connecting proteins... "
  connections = {}
    
  genes.each_key do |key|
  
    genes[key].proteins.each do |prot|
      interactions = get_connections(prot)
      if (interactions != [])
        connections[prot] = interactions
        break
      end
    end
    
  end
  
  puts "Done"
  
  
  print "Looking for more interactions... "
  
  total_connections = {}
  connections.each_key do |key|
    total_connections[key] = connections[key] unless total_connections.key?(key)
    
    connections[key].each do |prot|
      if (total_connections.key?(prot))
        next
      elsif (connections.key?(prot))
        total_connections[prot] = connections[prot]
      else 
        interactions = get_connections(prot)
        total_connections[prot] = interactions if (interactions != [])
      end  
    end
  end
  
  puts "Done"

  
  networks = {}
  
  genes.each_key do |gene_id|
    
    new_net = {}
    
    genes[gene_id].proteins.each do |first|
      
      next unless (connections.key?(first))
      
      new_net[first] = total_connections[first] # Connects first level with second
      
      connections[first].each do |second|
        new_net[second] = total_connections[second]  # Connects second level with third
      end
      
      networks[gene_id] = InteractionNetwork.new(:connections => new_net)  # Create object network
      networks[gene_id].get_nodes(proteins)
      networks[gene_id].get_gnodes()
      
    end
  end
  
  return networks
  
end



def generate_report(networks)

  out_file = File.open("Report.txt", "w")
  count = 0
  out_file.puts("FINAL REPORT\n\n")

  networks.each_value do |net|

    next unless net.filter_singles(net)

    count += 1
    out_file.print("Network #{count}: ")
    net.report(out_file)

  end

  puts "A file called Report.txt has been created to contain the networks found"

end



## ----- MAIN ----- ##

abort("File missing. Please introduce a file with the Arabidopsis genes (ArabidopsisSubNetwork_GeneList.txt)") unless ARGV[0]
puts "This will take a few minutes, be patient :)"
kegg_pathways = access_kegg("ath")
genes = create_genes(ARGV[0], kegg_pathways)
proteins = get_proteins(genes)
networks = create_networks(genes, proteins)
generate_report(networks)

