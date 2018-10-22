# Seed stock class

require './gene_class.rb'

class SeedStock
  
  attr_accessor :seed_stock  
  attr_accessor :mutant_geneID
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams_remaining
  
  def initialize (params = {})
    @seed_stock = params.fetch(:seed_stock, 'unknown seed')
    @mutant_geneID = params.fetch(:mutant_geneID, "0000000")
    @last_planted = params.fetch(:last_planted, "00/00/0000")
    @storage = params.fetch(:storage, 'unknown')
    @grams_remaining = params.fetch(:grams_remaining, 0).to_i
  end
  
  def planting_seeds(number)
    # This function substracts the desire number of grams of seeds in the variable grams_remaining
    
    if (@grams_remaining > number)
      @grams_remaining = @grams_remaining - number
    else
      @grams_remaining = 0
      puts "WARNING: we have run out of Seed Stock #{@seed_stock}"
    end
  end
  
end


def create_seedstock(list_genes, in_file)
  # This function creates instances of the class Gene from the lines in the database seed_stock_data.tsv
  
  first_line = true
  list_seeds = {}
  
  return false unless (File.file?(in_file))  # Check if the file exists
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      
      # Check if the file is the right one
      if (line =~ /Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining\n/)
        first_line = false
        next
      else
        return false
      end
      
    else
      elements = line.split("\t")  # Create an array with each element in the line
      if (list_genes.include? elements[1])  # Check if the attribute mutant_geneID can be linked to a Gene object with the same gene ID
        new_seed = SeedStock.new(:seed_stock => elements[0],
                                 :mutant_geneID => list_genes[elements[1]],
                                 :last_planted => elements[2],
                                 :storage => elements[3],
                                 :grams_remaining => elements[4])
        list_seeds[elements[0]] = new_seed  # Store the object in a hash with the key Seed Stock
      else
        abort("ERROR: Cannot associate seed stocks with genes in databases.")
      end
    end
  end
  
  return list_seeds
  
end