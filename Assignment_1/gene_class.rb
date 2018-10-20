# Gene class

class Gene
  
  attr_accessor :ID  
  attr_accessor :name
  attr_accessor :mutant_phenotype
  
  def initialize (params = {})
    @ID = params.fetch(:ID, 'unknown gene')
    abort("Wrong gene IDs") unless @ID =~ /A[Tt]\d[Gg]\d\d\d\d\d/ 
    @name = params.fetch(:name, "0000000")
    @mutant_phenotype = params.fetch(:mutant_phenotype, "0000000") 
  end
  
end


def create_genes(in_file)
  
  first_line = true
  list_genes = {}
  
  File.open(in_file, "r").each do |line|
    if (first_line)
      first_line = false
      next
    
    else
      elements = line.split("\t")
      new_gene = Gene.new(:ID => elements[0], :name => elements[1], :mutant_phenotype => elements[2])
      list_genes[elements[0]] = new_gene
    end
  end
  
  return list_genes
  
end