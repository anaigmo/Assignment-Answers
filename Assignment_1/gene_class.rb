# Gene class

class Gene
  
  attr_accessor :ID  
  attr_accessor :name
  attr_accessor :mutant_phenotype
  attr_accessor :linked_to
  
  def initialize (params = {})
    @ID = params.fetch(:ID, 'unknown gene')
    abort("ERROR: Wrong gene IDs in gene file.") unless @ID =~ /A[Tt]\d[Gg]\d\d\d\d\d/ 
    @name = params.fetch(:name, "0000000")
    @mutant_phenotype = params.fetch(:mutant_phenotype, "0000000")
    @linked_to = nil
  end
  
end


def create_genes(in_file)
  # This function creates instances of the class Gene from the lines in the database gene_information.tsv
  
  first_line = true
  list_genes = {}
  
  return false unless (File.file?(in_file))  # Check that the file exists
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      
      # Check if the file is the right one
      if (line =~ /Gene_ID\tGene_name\tmutant_phenotype\n/)
        first_line = false
        next
      else
        return false
      end
    
    else
      elements = line.split("\t")  # Create an array with each element in the line
      new_gene = Gene.new(:ID => elements[0], :name => elements[1], :mutant_phenotype => elements[2])  # Create the object
      list_genes[elements[0]] = new_gene  # Store the object in a file, with kei the variable ID
    end
  end
  
  return list_genes
  
end