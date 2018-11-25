require 'bio'
require 'net/http'


## ----- FUNCTIONS ----- ##


def fetch(uri_str)
  # this "fetch" routine does some basic error-handling.
  # This entire function has been originally written by Mark Wilkinson

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
  # This function creates instances of the class Gene from the lines in ArabidopsisSubNetwork_GeneList.txt

  abort("The file does not exist") unless (File.file?(in_file))  # Check that the file exists

  print "Retrieving sequences from EMBL... "

  list_genes = {}

  File.open(in_file, "r").each do |gene_id|

    gene_id = gene_id.chomp
    url = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene_id}"
    res = fetch(url)  # we really should check that the return value is valid, but...
    gene = Bio::EMBL.new(res.body)
    list_genes[gene_id] = gene

  end

  puts "Done"

  return list_genes

end



def create_feature(beginning, strand)

  new_feats = []

  beginning.each do |b_pos|

    if strand == "-"
      nfeat = Bio::Feature.new('repeat', "complement(#{b_pos}..#{b_pos+5})")
    elsif strand == "+"
      nfeat = Bio::Feature.new('repeat', "#{b_pos}..#{b_pos+5}")
    end

    nfeat.append(Bio::Feature::Qualifier.new('repeat_motif', 'CTTCTT'))
    nfeat.append(Bio::Feature::Qualifier.new('note', 'found branded new'))  # en fin
    nfeat.append(Bio::Feature::Qualifier.new('strand', strand))

    new_feats.push(nfeat)

  end

  return new_feats

end



def add_feature(gene, feat, strand, pattern, added_feats)

  pos_raw = /(\d+)\.\.(\d+)/.match(feat.position)
  pos_exon = [pos_raw[1].to_i, pos_raw[2].to_i]

  seq = gene.seq[pos_exon[0]..pos_exon[1]]

  match_begin = []
  seq.scan(pattern) {match_begin.push($~.begin(0))}

  pos_repeat = []
  match_begin.each do |pos|

    npos = pos + pos_exon[0]  # desfase por encontrar la repeticion ASLDKFJAÑSGAÑWEOGNAÑLKÑALSRKFJAÑERKJL ¿FALTA +1?
    next if added_feats.include?(npos)  # Removes duplicates

    next unless pattern.match(seq[pos+3..pos+5])  # complete repetition

    pos_repeat.push(npos)
    added_feats.push(npos)

  end



  new_feats = create_feature(pos_repeat, strand)

  new_feats.each do |nfeat|
    gene.features << nfeat
  end

end



def write_gff3(genes)

  out_file = File.open("Repeats.gff3", "w")
  out_file.puts("##gff-version 3")
  no_repeats = []

  genes.each_key do |key|

    gene = genes[key].to_biosequence
    count = 0

    gene.features.each do |feat|

      next unless feat.feature == "repeat"

      count += 1
      pos_match = /(\d+)\.\.(\d+)/.match(feat.position)
      pos = [pos_match[1].to_i, pos_match[2].to_i]
      strand = feat.assoc["strand"]
      att = "ID=#{key}_CTTCTT_#{count};name=repeat_CTTCTT"

      out_file.puts("Chr#{gene.entry_id}\tEMBL\trepeat_unit\t#{pos[0]}\t#{pos[1]}\t.\t#{strand}\t.\t#{att}")

    end

    no_repeats.push(key) if count == 0

  end

  out_file.close
  puts "A file 'Repeats.gff3' containing the new features that describe the pattern found in the exons of the genes given has been created."

  report_no_repeats(no_repeats) if no_repeats != []

end



def report_no_repeats(no_repeats)

  out_file = File.open("No_repeats_genes.txt", "w")

  no_repeats.each do |gene|
    out_file.puts(gene)
  end

  print "Some genes doesn't present the pattern 'CTTCTT' in any exon."
  puts "They are contained in the file 'No_repeats_genes.txt.'"

end



def write_gff3_chr(genes)

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
  puts "A file 'Repeats_chr.gff3' with different coordinates has been created."

end




## ----- MAIN ----- ##

abort("File missing. Please introduce a file with the Arabidopsis genes (ArabidopsisSubNetwork_GeneList.txt)") unless ARGV[0]

genes = get_genes(ARGV[0])  # Create gene objects from the list in the file given


genes.each_value do |gene|

  gene = gene.to_biosequence
  added_feats = []

  gene.features.each do |feat|

    if feat.feature == "exon"

      if /:/.match(feat.position)  ## referidos a un gen
        next
      elsif /complement/.match(feat.position)
        add_feature(gene, feat, "-", /aag/, added_feats)
      else
        add_feature(gene, feat, "+", /ctt/, added_feats)
      end

    end

  end

end


write_gff3(genes)

write_gff3_chr(genes)
