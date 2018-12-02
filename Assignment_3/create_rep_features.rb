## ------------------------------------------- Assignment 3 -------------------------------------------  ##
#
# This program has been created by Ana Iglesias Molina for the subject Bioinformatics Programming Challenges.
#
# It takes the file 'ArabidopsisSubNetwork_GeneList.txt', creates Bio::EMBL objects of the genes contained in
# the file, and looks for the repetition 'CTTCTT' in its exons' sequences. When it finds one, it saves it as
# a Bio::Feature object in the Bio::EMBL object of its correspondent gene. All the new features created are
# later printed in two gff3 files, one with the positions referred to the gene, and the other to the chromosome.
# Moreover, the genes which don't contain this repetition are saved as a list in the file 'No_repeats_genes.txt'.
#

require 'bio'
require 'net/http'


## ----- FUNCTIONS ----- ##


def fetch(uri_str)
  # This function returns the content of an uri in the variable 'response' and does some basic error handling
  # The entire function has been originally written by Mark Wilkinson

  address = URI(uri_str)
  response = Net::HTTP.get_response(address)

  case response   # the "case" block allows you to test various conditions... it is like an "if", but cleaner!
  when Net::HTTPSuccess then  # when response is of type Net::HTTPSuccess
    return response  # return that response object
  else
    raise Exception, "Something went wrong... the call to #{uri_str} failed; type #{response.class}"
    response = false
    return response  # now we are returning False
  end

end



def get_genes(in_file)
  # This function creates instances of Bio::EMBL from the genes in ArabidopsisSubNetwork_GeneList.txt

  abort("The file does not exist") unless (File.file?(in_file))  # Check that the file exists

  print "Retrieving sequences from EMBL... "

  list_genes = {}

  File.open(in_file, "r").each do |gene_id|

    gene_id = gene_id.chomp
    url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene_id}"
    res = fetch(url)
    gene = Bio::EMBL.new(res.body)
    list_genes[gene_id] = gene

  end

  puts "Done"

  return list_genes

end



def analyze_exons(genes)
  # This function look for the exons' features in each gene, evaluates the position of the exon,
  # and calls the function that looks for the pattern in that sequence (add_feature())
  # 'genes' -> hash that contains the name of the gene as a key, and the Bio::EMBL object as value

  genes.each_value do |gene|

    gene = gene.to_biosequence
    added_feats = []

    gene.features.each do |feat|

      if feat.feature == "exon"

        if /:/.match(feat.position)
          next
        elsif /complement/.match(feat.position)
          add_feature(gene, feat, "-", /aag/, added_feats)
        else
          add_feature(gene, feat, "+", /ctt/, added_feats)
        end

      end

    end

  end

  return genes

end



def create_feature(beginning, strand)
  # This function creates an object Bio::Feature that contains the repetition cttctt found in an exon
  # 'beggining' ->  array that contains the beginning indexes of the repetition in an exon
  # 'strand' -> string that tells if the positions are in the + or - strand


  new_feats = []

  beginning.each do |b_pos|

    if strand == "-"
      nfeat = Bio::Feature.new('repeat', "complement(#{b_pos}..#{b_pos+5})")
    elsif strand == "+"
      nfeat = Bio::Feature.new('repeat', "#{b_pos}..#{b_pos+5}")
    end

    nfeat.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
    nfeat.append(Bio::Feature::Qualifier.new('strand', strand))

    new_feats.push(nfeat)

  end

  return new_feats

end



def add_feature(gene, feat, strand, pattern, added_feats)
  # This function looks for a pattern in the exon given by the feature, and adds it as a new feature of the
  # Bio::Sequence object of gene
  # 'gene' -> Bio::Sequence object of gene
  # 'feat' -> Bio::Feature object of the gene's exon
  # 'strand' -> strand where the exon is, string that can take value '+' or '-'
  # 'pattern' -> regular expression to look for in the sequence
  # 'added_feats' -> array that contains all the beginning positions of the patterns found in a gene

  pos_raw = /(\d+)\.\.(\d+)/.match(feat.position)
  pos_exon = [pos_raw[1].to_i - 1, pos_raw[2].to_i - 1]  # difference of one position because of index

  seq = gene.seq[pos_exon[0]..pos_exon[1]]  # extract the sequence of exon

  match_begin = []
  seq.scan(pattern) {match_begin.push($~.begin(0))}  # looks for pattern in the sequence

  pos_repeat = []
  match_begin.each do |pos|  # for each position where the pattern has been found

    npos = pos + pos_exon[0]  # position of the pattern in the sequence (not only exon, like before)
    next if added_feats.include?(npos)  # avoid duplicates

    next unless pattern.match(seq[pos+3..pos+5])  # complete repetition (cttctt)

    pos_repeat.push(npos)
    added_feats.push(npos)

  end

  new_feats = create_feature(pos_repeat, strand)  # create object Bio::Feature with the info extracted above

  new_feats.each do |nfeat|
    gene.features << nfeat  # add feature to Bio::Sequence object of gene
  end

end



def write_gff3(genes)
  # This function writes in a gff3 format file (Repeats.gff3) the new features created of the patterns found in the exons
  # The positions of each feature are referred to the gene, not the chromosome
  # 'genes' -> hash that contains the name of the gene as a key, and the Bio::EMBL object as value

  out_file = File.open("Repeats.gff3", "w")
  out_file.puts("##gff-version 3")
  no_repeats = []

  genes.each_key do |key|

    gene = genes[key].to_biosequence
    count = 0

    gene.features.each do |feat|

      next unless feat.feature == "repeat"  # name of the feature

      count += 1
      pos_match = /(\d+)\.\.(\d+)/.match(feat.position)
      pos = [pos_match[1].to_i + 1, pos_match[2].to_i + 1]  # difference of one position because of index
      strand = feat.assoc["strand"]
      att = "ID=#{key}_CTTCTT_#{count};name=repeat_CTTCTT"

      out_file.puts("Chr#{gene.entry_id}\tEMBL\trepeat_unit\t#{pos[0]}\t#{pos[1]}\t.\t#{strand}\t.\t#{att}")

    end

    no_repeats.push(key) if count == 0  # genes without the pattern in their exons

  end

  out_file.close
  puts "A file 'Repeats.gff3' containing the new features that describe the pattern found in the exons of the genes given has been created."

  report_no_repeats(no_repeats) if no_repeats != []

end



def report_no_repeats(no_repeats)
  # This function writes a file 'No_repeats_genes.txt' which contains a list of the names of the genes that
  # don't contain the pattern in their exon sequences.
  # 'no_repeats' -> array with the names of the genes

  out_file = File.open("No_repeats_genes.txt", "w")

  no_repeats.each do |gene|
    out_file.puts(gene)
  end

  print "Some genes doesn't present the pattern 'CTTCTT' in any exon."
  puts "They are contained in the file 'No_repeats_genes.txt.'"

end



def write_gff3_chr(genes)
  # This function writes in a gff3 format file (Repeats_chr.gff3) the new features created of the patterns found in the exons
  # The positions of each feature are referred to the chromosome
  # 'genes' -> hash that contains the name of the gene as a key, and the Bio::EMBL object as value

  out_file = File.open("Repeats_chr.gff3", "w")
  out_file.puts("##gff-version 3")

  genes.each_key do |key|

    gene = genes[key].to_biosequence
    count = 0

    gene.features.each do |feat|

      next unless feat.feature == "repeat"

      count += 1
      pos_match = /(\d+)\.\.(\d+)/.match(feat.position)

      p_accession = gene.primary_accession.split(":")
      ref = p_accession[3].to_i  # position where the gene starts in the genome coordinates reference

      pos = [pos_match[1].to_i + ref, pos_match[2].to_i + ref]
      strand = feat.assoc["strand"]
      att = "ID=#{key}_CTTCTT_#{count};name=repeat_CTTCTT"

      out_file.puts("Chr#{gene.entry_id}\tEMBL\trepeat_unit\t#{pos[0]}\t#{pos[1]}\t.\t#{strand}\t.\t#{att}")

    end

  end

  out_file.close
  puts "A file 'Repeats_chr.gff3' with positions referred to the chromosome has been created."

end




## ----- MAIN ----- ##

abort("File missing. Please introduce a file with the Arabidopsis genes (ArabidopsisSubNetwork_GeneList.txt)") unless ARGV[0]

genes = get_genes(ARGV[0])  # Create Bio::EMBL objects of the genes in list of the file given

genes = analyze_exons(genes)  # Look for the pattern in the exons of each gene, create a new feature an add it to the Bio::EMBL gene objects

write_gff3(genes)  # Write the new features in a gff3 object, with the positions referred to the gene

write_gff3_chr(genes)  # Write the new features in a gff3 object, with the positions referred to the chromosome
