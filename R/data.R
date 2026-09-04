# Documentation for the shipped datasets. Built by data-raw/make-datasets.R
# from the UCINET ##h/##d files, so labels, relation names, 2-mode shapes and
# multi-relation stacks are the ones UCINET itself uses.
#
# Networks are xucinet objects; node attributes are plain data frames keyed by
# node label (SPEC D1), named <dataset>_attr.

#' Baker's social work journals
#'
#' Citations among 20 social work journals for 1985-1986: cell (i, j) is the
#' number of citations from articles in journal i to articles in journal j.
#' Baker found a core-periphery structure, and argued that American journals
#' are less likely to engage the international literature.
#'
#' @format An `xucinet` object, 20 x 20, one valued directed relation.
#' @source Baker, D. R. (1992). A structural analysis of social work journal
#'   network: 1985-1986. *Journal of Social Service Research*, 15(3-4), 153-168.
#' @section Book sections: 12.8 (practice 12.5).
#' @examples
#' xdensity(baker_journals)
"baker_journals"

#' Bernard and Killworth ham radio operators
#'
#' One of the Bernard-Killworth-Sailer informant-accuracy studies. Amateur radio
#' calls over one month, monitored by a voice-activated recorder, alongside the
#' operators' own retrospective rankings of how often they talked to each other.
#' The pair is the classic test of whether people can recall who they interact
#' with.
#'
#' @format An `xucinet` object, 44 x 44, two relations:
#' \describe{
#'   \item{Calls}{calls observed over the one-month period}
#'   \item{Recall}{each operator's ranking of how often they talked to each
#'     other operator, 0 (no interaction) to 9}
#' }
#' @source Killworth, B. and Bernard, H. (1976). Informant accuracy in social
#'   network data. *Human Organization*, 35, 269-286; and the two sequels,
#'   *Human Communication Research* 4, 3-18 (1977) and *Social Networks* 2,
#'   19-46 (1979).
#' @section Book sections: 8.8.
#' @examples
#' xrelations(bkham)
"bkham"

#' Camp 92, weeks 2 and 3
#'
#' Interaction rankings among 18 people at the 1992 NSF Summer Institute on
#' Research Methods in Cultural Anthropology, a three-week course. Each
#' respondent sorted cards bearing the other participants' names in order of how
#' much interaction they had, so 1 is the person interacted with most.
#' Collected at the end of the second and third weeks.
#'
#' @format An `xucinet` object, 18 x 18, two relations:
#' \describe{
#'   \item{MostInteractionsT2}{interaction rank at the end of week 2}
#'   \item{MostInteractionsT3}{interaction rank at the end of week 3}
#' }
#' @source Borgatti, S. P., Bernard, H. R., Pelto, P., Ryan, G. and DeJordy, R.
#'   (2012). The Camp '92 dataset. *Connections*, 32(1), 51-53.
#' @section Book sections: 2.3, 2.4, 5.5.7, 11.10, 12.10, 14.7 (practices 5.7, 7.7).
#' @seealso [camp92_attr]
#' @examples
#' xdensity(camp92)
"camp92"

#' Camp 92 participant attributes
#'
#' @format A data frame, 18 rows keyed by participant name, 3 columns:
#' \describe{
#'   \item{Gender}{1 = female, 2 = male}
#'   \item{Role}{1 = participant, 2 = instructor}
#'   \item{Betweenness}{betweenness centrality, as reported in the book}
#' }
#' @source As [camp92].
#' @seealso [camp92]
#' @examples
#' head(camp92_attr)
"camp92_attr"

#' Campnet
#'
#' The binary interaction network among the same 18 people as [camp92], used as
#' the running example through much of the book. A tie means the respondent
#' placed that person among those they interacted with most.
#'
#' There is no `campnet_attr`. These are the same 18 participants as [camp92],
#' so their attributes are in [camp92_attr], whose row names line up with this
#' network's node for node.
#'
#' @format An `xucinet` object, 18 x 18, one binary directed relation.
#' @source Borgatti, S. P., Bernard, H. R., Pelto, P., Ryan, G. and DeJordy, R.
#'   (2012). The Camp '92 dataset. *Connections*, 32(1), 51-53.
#' @section Book sections: 5.2.3.
#' @seealso [camp92], [camp92_attr]
#' @examples
#' xdensity(campnet)
"campnet"

#' Scientists at an applied research institute (504 nodes)
#'
#' The main component of [pv960]: how much time, in days, scientists at a large
#' applied research institute worked on projects together. Derived from a
#' 960-by-3154 person-by-project matrix by the sum-of-minimums method.
#'
#' @format An `xucinet` object, 504 x 504, one valued undirected relation.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 7.2.3, 7.3.2, 7.4.1, 7.5.1-7.5.3 (practices 7.3, 7.6).
#' @seealso [pv504_attr], [pv960]
#' @examples
#' dim(pv504)
"pv504"

#' Scientist attributes (504 nodes)
#'
#' @format A data frame, 504 rows keyed by scientist id, 39 columns of
#'   personnel and project variables, including `Years` (years employed), `Sex`
#'   (1 = female, 2 = male), `DeptID` (functional department, reflecting
#'   discipline), the `disc_1`-`disc_3` discipline codes, the percentage-of-time
#'   columns ending `Perc`, and precomputed `Degree`, `Closeness`,
#'   `Betweenness` and `Eigenvector` centralities.
#' @source As [pv504].
#' @seealso [pv504]
#' @examples
#' names(pv504_attr)
"pv504_attr"

#' Scientists at an applied research institute (960 nodes)
#'
#' The full network behind [pv504]: time in days that 960 scientists worked on
#' projects together, projected from a 960-by-3154 person-by-project matrix by
#' the sum-of-minimums method. If person A spent 1 day on a project and person B
#' spent 5, the pair is credited with 1 day.
#'
#' @format An `xucinet` object, 960 x 960, one valued undirected relation.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 11.10.
#' @seealso [pv504]
#' @examples
#' dim(pv960)
"pv960"

#' Burkhardt and Brass government agency
#'
#' Who communicated with whom about work at a government agency, at five points
#' in time spanning the introduction of a new computer system. Burkhardt and
#' Brass used the data to ask whether technological change reshapes the network
#' or merely follows it.
#'
#' @format An `xucinet` object, 73 x 73, five relations `InteractionT1` to
#'   `InteractionT5`, one per wave.
#' @source Burkhardt, M. E. and Brass, D. J. (1990). Changing patterns or
#'   patterns of change: the effects of a change in technology on social network
#'   structure and power. *Administrative Science Quarterly*, 35, 104-127.
#' @section Book sections: 7.6 (practices 5.3, 7.7).
#' @examples
#' xrelations(burkhardt)
"burkhardt"

#' Davis's southern women
#'
#' The canonical two-mode dataset: attendance by 18 women at 14 social events in
#' a Mississippi town in the 1930s. Cell (i, j) is 1 if woman i attended event
#' j. Breiger used it to make the argument about the duality of persons and
#' groups, and it has been a benchmark for two-mode methods ever since.
#'
#' @format An `xucinet` object, 18 women x 14 events, 2-mode, binary.
#' @source Davis, A., Gardner, B. and Gardner, M. (1941). *Deep South*. Chicago:
#'   University of Chicago Press. See also Breiger, R. (1974). The duality of
#'   persons and groups. *Social Forces*, 53, 181-190.
#' @section Book sections: 2.5, 3.5, 13.1-13.7.2 (practices 13.1-13.5).
#' @examples
#' xdensity(davis)
"davis"

#' Freeman's EIES researchers
#'
#' An early experiment in computer-mediated communication. Academics interested
#' in interdisciplinary research could contact each other through the Electronic
#' Information Exchange System; the data record acquaintance before and after,
#' and the messages actually sent. The 32 people here are those who completed
#' the study.
#'
#' @format An `xucinet` object, 32 x 32, three relations:
#' \describe{
#'   \item{TIME_1}{acquaintance at the start: 4 = close personal friend,
#'     3 = friend, 2 = have met, 1 = heard of but not met, 0 = unknown}
#'   \item{TIME_2}{the same scale at the end of the study}
#'   \item{NUMBER_OF_MESSAGES}{messages sent through the system}
#' }
#' @source Freeman, S. C. and Freeman, L. C. (1979). *The networkers network: a
#'   study of the impact of a new communications medium on sociometric
#'   structure*. Social Science Research Reports No. 46. Irvine, CA: University
#'   of California.
#' @section Book sections: 8.8, 10.7, 15.6.2, 15.8 (practice 15.6).
#' @seealso [eies_attr]
#' @examples
#' xrelations(eies)
"eies"

#' EIES researcher attributes
#'
#' @format A data frame, 32 rows keyed by researcher id, 2 columns:
#' \describe{
#'   \item{Citations}{citations to the person's work in the Social Science
#'     Citation Index at the start of the study}
#'   \item{Discipline}{1 = sociology, 2 = anthropology,
#'     3 = mathematics/statistics, 4 = other}
#' }
#' @source As [eies].
#' @seealso [eies]
#' @examples
#' table(eies_attr$Discipline)
"eies_attr"

#' Doctorates by field and year
#'
#' Counts of doctorates awarded in the United States, cross-classified by
#' academic field and year. A two-mode table of the kind correspondence analysis
#' was designed for, and the book's worked example for that method.
#'
#' @format An `xucinet` object, 12 fields x 8 years, 2-mode, valued.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 6.3 (practice 6.2).
#' @examples
#' as.matrix(doctorates)[1:4, 1:4]
"doctorates"

#' Hawthorne bank wiring room
#'
#' Observations of 14 Western Electric employees in the bank wiring room, from
#' the Hawthorne studies: two inspectors (I1, I3), three solderers (S1-S3) and
#' nine wiremen (W1-W9), working in a single room. Six kinds of interaction were
#' recorded. Best known through Homans's reanalysis and the Breiger, Boorman and
#' Arabie CONCOR analysis.
#'
#' @format An `xucinet` object, 14 x 14, six relations: `Games` (horseplay),
#'   `Conflict` (arguments about the windows), `Friendship`, `Antagonistic`,
#'   `Help` (helping others with work) and `TradeJobs` (trading job
#'   assignments).
#' @source Roethlisberger, F. and Dickson, W. (1939). *Management and the
#'   worker*. Cambridge University Press. See also Homans, G. (1950). *The human
#'   group*, and Breiger, R., Boorman, S. and Arabie, P. (1975). *Journal of
#'   Mathematical Psychology*, 12, 328-383.
#' @section Book sections: 2.2, 2.3, 2.8, 3.4, 5.4.6, 5.9, 7.4.3, 8.2, 8.6.2,
#'   9.9, 11.2-11.2.2, 12.10, 14.7 (practices 7.5, 8.1, 8.4, 9.6, 11.1).
#' @examples
#' xrelations(wiring)
"wiring"

#' Driving distances between US cities
#'
#' Road distances in miles between nine major US cities. A proximity matrix
#' rather than a social network, used in the book to show how the same tools
#' apply to any square matrix, and as the worked example for scaling.
#'
#' @format An `xucinet` object, 9 x 9, one valued symmetric relation.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 6.2, 6.4, 6.6 (practices 6.1, 6.3).
#' @examples
#' as.matrix(cities)
"cities"

#' Polar station crew
#'
#' Strong ties among the 22 members of an over-wintering polar research station
#' crew, recorded at two points in time. One of Jeffrey Johnson's studies of
#' isolated, confined groups.
#'
#' @format An `xucinet` object, 22 x 22, two relations `StrongTiesT1` and
#'   `StrongTiesT2`.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 3.2, 3.7, 4.2, 4.3, 4.5, 4.6, 10.7, 12.10.
#' @examples
#' xdensity(polarstation)
"polarstation"

#' Kapferer's tailor shop
#'
#' Interactions in a Zambian tailor shop observed by Kapferer over ten months,
#' spanning extended negotiations for higher wages. Two kinds of tie recorded at
#' two times seven months apart, which is what makes the data a standard test
#' for how alliances shift.
#'
#' @format An `xucinet` object, 39 x 39, four relations:
#'   `SociationalT1`, `SociationalT2` (friendship and socioemotional ties) and
#'   `InstrumentalT1`, `InstrumentalT2` (work and assistance ties).
#' @source Kapferer, B. (1972). *Strategy and transaction in an African
#'   factory*. Manchester University Press.
#' @section Book sections: 11.1, 11.3 (practices 10.3, 11.2).
#' @examples
#' xrelations(kaptail)
"kaptail"

#' Knecht's Dutch school class
#'
#' Friendship among 26 pupils aged 11-13 in a Dutch school class at four points
#' in one year, collected for Knecht's dissertation on how friendship selection
#' and peer influence unfold together. The attributes carry the delinquency and
#' alcohol measures that make it a standard co-evolution example.
#'
#' @format An `xucinet` object, 26 x 26, five relations: `FriendshipT1` to
#'   `FriendshipT4`, plus `CoattendedPrimary` (whether the pair knew each other
#'   from primary school).
#' @source Knecht, A. (2008). *Friendship selection and friends' influence:
#'   dynamics of networks and actor attributes in early adolescence*. PhD
#'   dissertation, University of Utrecht.
#' @section Book sections: 15.6.3, 15.8 (practice 15.7).
#' @seealso [knecht_attr]
#' @examples
#' xrelations(knecht)
"knecht"

#' Knecht pupil attributes
#'
#' @format A data frame, 26 rows keyed by pupil id, 14 columns: `Sex2M`
#'   (2 = male), `Age` at wave 1, `Ethnicity`, `Religion`, `DelinquencyT1` to
#'   `DelinquencyT4`, `AlcoholT2` to `AlcoholT4` (alcohol was not measured at
#'   wave 1), `CapacityT0`, `PresenceStarts` and `PresenceEnds`.
#' @source As [knecht].
#' @seealso [knecht]
#' @examples
#' head(knecht_attr)
"knecht_attr"

#' Krackhardt's high-tech managers
#'
#' The 21 managers of a high-tech company on the US west coast, with just over
#' 100 employees. Advice and friendship come from the managers themselves;
#' the reporting relation comes from company documents, which is why it is the
#' standard example of a formal hierarchy sitting under an informal network.
#'
#' @format An `xucinet` object, 21 x 21, three relations:
#' \describe{
#'   \item{Advice}{who the manager went to for advice}
#'   \item{Friendship}{who the manager considers a friend}
#'   \item{ReportTo}{who the manager reported to}
#' }
#' @source Krackhardt, D. (1987). Cognitive social structures. *Social
#'   Networks*, 9, 104-134.
#' @section Book sections: 3.7, 5.2.2, 5.5.8, 5.9, 7.2-7.3.2, 8.4.1-8.5.2, 9.9,
#'   10.2.1-10.5, 14.5.2.
#' @seealso [hightech_attr]
#' @examples
#' xdensity(hightech, relation = "Advice")
"hightech"

#' High-tech manager attributes
#'
#' @format A data frame, 21 rows keyed by manager id, 4 columns:
#' \describe{
#'   \item{Age}{age in years}
#'   \item{Tenure}{length of service in years}
#'   \item{Level}{1 = CEO, 2 = vice president, 3 = manager}
#'   \item{Department}{department code 1-4, with the CEO in department 0}
#' }
#' @source As [hightech].
#' @seealso [hightech]
#' @examples
#' table(hightech_attr$Level)
"hightech_attr"

#' Mainas terrorist contact network
#'
#' Known contacts among 4275 people, obtained from Europol by Mainas and
#' analysed by its Counter-Terrorism and Analysis units. The kind of tie was not
#' disclosed. The largest network the package ships, and a realistic test of
#' routines on a sparse graph.
#'
#' @format An `xucinet` object, 4275 x 4275, one valued relation.
#' @source Mainas, E. D. (2012). The analysis of criminal and terrorist
#'   organisations as social network structures: a quasi-experimental study.
#'   *International Journal of Police Science and Management*, 14(3), 264-282.
#' @section Book sections: 11.7 (ASNR).
#' @examples
#' dim(mainas_terro)
"mainas_terro"

#' Newcomb's fraternity
#'
#' Weekly sociometric rankings from 17 men sharing off-campus housing at the
#' University of Michigan in autumn 1956, recruited as incoming transfer
#' students who had never met. Each man ranked the other 16 with no ties
#' allowed, so 1 is the first preference. Fifteen weeks are present; week 9 is
#' missing from the original study.
#'
#' @format An `xucinet` object, 17 x 17, fifteen relations `PreferenceT00` to
#'   `PreferenceT15`.
#' @source Newcomb, T. (1961). *The acquaintance process*. New York: Holt,
#'   Rinehart and Winston.
#' @section Book sections: 7.4.2, 14.5.2 (ASNR).
#' @examples
#' xnrelations(newfrat)
"newfrat"

#' Padgett's Florentine families
#'
#' Marriage alliances and business ties among 16 Renaissance Florentine
#' families, coded by Padgett from historical documents, and the standard
#' illustration of how a family with middling wealth (the Medici) can hold a
#' commanding structural position. The original coding is symmetric, which is
#' natural for marriage and more debatable for finance.
#'
#' @format An `xucinet` object, 16 x 16, two relations `Marriage` and
#'   `Business`, both binary and symmetric.
#' @source Padgett, J. F. and Ansell, C. K. (1993). Robust action and the rise
#'   of the Medici, 1400-1434. *American Journal of Sociology*, 98, 1259-1319.
#' @section Book sections: 3.2, 4.6, 7.3.3, 9.3.4, 9.3.5, 14.5.1 (ASNR).
#' @seealso [padgett_attr]
#' @examples
#' xdensity(padgett, relation = "Marriage")
"padgett"

#' Florentine family attributes
#'
#' @format A data frame, 16 rows keyed by family name, 3 columns:
#' \describe{
#'   \item{Wealth}{net wealth in 1427, in thousands of lira}
#'   \item{NoPriors}{seats on the civic council held between 1282 and 1344}
#'   \item{NoTies}{total business or marriage ties in the full 116-family data}
#' }
#' @source As [padgett].
#' @seealso [padgett]
#' @examples
#' padgett_attr[order(-padgett_attr$Wealth), ][1:5, ]
"padgett_attr"

#' Pane's training squad
#'
#' Who trusts whom among 23 members of a training squad, collected in a study of
#' how newcomers are socialised into an organisation.
#'
#' @format An `xucinet` object, 23 x 23, one binary directed relation.
#' @source Pane, A. (2006). *Examining newcomers' socialization into an
#'   organization*. Unpublished DPsych thesis, University of Melbourne. See also
#'   Robins, G., Pattison, P. and Wang, P. (2009). *Social Networks*, 31(2),
#'   105-117.
#' @section Book sections: 15.4 (ASNR).
#' @examples
#' xdensity(pane_training)
"pane_training"

#' Sampson's monastery
#'
#' Sampson's ethnographic study of novices preparing to join a monastic order in
#' New England, taken at the point where the community was breaking apart. Each
#' novice named his top three choices on each of several affect relations, coded
#' 3 for the first choice down to 1 for the third, so the data are ranked rather
#' than binary.
#'
#' @format An `xucinet` object, 18 x 18, ten relations: `LikeT1`, `LikeT2`,
#'   `LikeT3`, `Dislike`, `Esteem`, `Disesteem`, `PositiveInfluence`,
#'   `NegativeInfluence`, `Praise` and `Blame`.
#' @source Sampson, S. (1969). *Crisis in a cloister*. Unpublished doctoral
#'   dissertation, Cornell University.
#' @section Book sections: 3.7, 12.3-12.7 (ASNR).
#' @examples
#' xrelations(sampson)
"sampson"

#' Trade flows before the 1929 crash
#'
#' Transaction flows between 15 countries in the years before the 1929 crash,
#' as used by Savage and Deutsch to argue for a statistical baseline against
#' which observed trade should be judged.
#'
#' @format An `xucinet` object, 15 x 15, one valued directed relation, in
#'   percentage of exports to each other country.
#' @source Savage, I. R. and Deutsch, K. W. (1960). A statistical model of the
#'   gross analysis of transaction flows. *Econometrica*, 28, 551-572.
#' @section Book sections: 7.2.1, 7.2.2 (ASNR).
#' @examples
#' rownames(as.matrix(trade_pre29))
"trade_pre29"

#' Papuan village taro exchange
#'
#' Gift-giving, specifically the exchange of taro, among 22 households in an
#' Orokaiva village in Papua. Schwimmer's point is that these ties define who
#' may properly mediate a request for help. Called Taro in UCINET.
#'
#' @format An `xucinet` object, 22 x 22, one binary symmetric relation.
#' @source Schwimmer, E. (1973). *Exchange in the social structure of the
#'   Orokaiva*. New York: St Martin's. See also Hage, P. and Harary, F. (1983).
#'   *Structural models in anthropology*. Cambridge University Press.
#' @section Book sections: 12.6 (ASNR).
#' @examples
#' xdensity(papuan_village)
"papuan_village"

#' Wolfe's primates
#'
#' Three months of interaction among a troop of monkeys observed in the wild by
#' Linda Wolfe as they sported by a river in Ocala, Florida.
#'
#' @format An `xucinet` object, 20 x 20, two relations:
#' \describe{
#'   \item{Kinship}{putative kin relationships among the animals}
#'   \item{JointPresence}{joint presence at the river, summed over all pairs}
#' }
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @section Book sections: 7.2.1, 7.2.2 (ASNR).
#' @seealso [wolfe_primates_attr]
#' @examples
#' xrelations(wolfe_primates)
"wolfe_primates"

#' Primate attributes
#'
#' @format A data frame, 20 rows keyed by animal id, 3 columns:
#' \describe{
#'   \item{Age}{age in years}
#'   \item{Sex}{1 = male, 2 = female}
#'   \item{Rank}{rank in the troop, 1 being highest}
#' }
#' @source As [wolfe_primates].
#' @seealso [wolfe_primates]
#' @examples
#' head(wolfe_primates_attr)
"wolfe_primates_attr"

#' Zachary's karate club
#'
#' The 34 members of a university karate club observed by Zachary between 1970
#' and 1972. A dispute split the club in two, and Zachary used an information
#' flow model to predict, from the network alone, which side each member would
#' take. Probably the most reused dataset in the field.
#'
#' @format An `xucinet` object, 34 x 34, two relations:
#' \describe{
#'   \item{Connection}{binary: 1 where tie strength is above zero}
#'   \item{Strength}{the number of contexts, out of eight, in which the pair
#'     were known to interact}
#' }
#' @source Zachary, W. (1977). An information flow model for conflict and
#'   fission in small groups. *Journal of Anthropological Research*, 33,
#'   452-473.
#' @section Book sections: 3.7, 8.3, 11.3-11.5 (ASNR).
#' @seealso [zachary_attr]
#' @examples
#' xdensity(zachary)
"zachary"

#' Karate club member attributes
#'
#' @format A data frame, 34 rows keyed by member id, 3 columns:
#' \describe{
#'   \item{Support}{faction membership from a max-flow / min-cut partition}
#'   \item{Strength}{strength of support for the chosen faction}
#'   \item{Club}{which club the member ended up in: 1 = Mr Hi's new club,
#'     34 = the original club}
#' }
#' @source As [zachary].
#' @seealso [zachary]
#' @examples
#' table(zachary_attr$Club)
"zachary_attr"

#' Lazega's corporate law firm
#'
#' Advice, co-working and friendship among 71 attorneys, partners and associates
#' alike, in a north-eastern US corporate law firm between 1988 and 1991. A
#' standard testbed for exponential random graph models, because the three
#' relations and the rich attribute set let you ask what predicts a tie.
#'
#' @format An `xucinet` object, 71 x 71, three relations:
#' \describe{
#'   \item{Advice}{colleagues gone to for non-technical professional advice}
#'   \item{Coworking}{colleagues worked with on at least one case}
#'   \item{Friendship}{colleagues socialised with outside work}
#' }
#' @source Lazega, E. (2001). *The collegial phenomenon: the social mechanisms
#'   of cooperation among peers in a corporate law partnership*. Oxford
#'   University Press. See also Snijders, T. A. B., Pattison, P. E., Robins,
#'   G. L. and Handcock, M. S. (2006). New specifications for exponential random
#'   graph models. *Sociological Methodology*, 99-153.
#' @seealso [lazega_attr]
#' @examples
#' xrelations(lazega)
"lazega"

#' Law firm attorney attributes
#'
#' @format A data frame, 71 rows keyed by attorney id, 7 columns:
#' \describe{
#'   \item{Status}{1 = partner, 2 = associate}
#'   \item{Gender}{1 = male, 2 = female}
#'   \item{Office}{1 = Boston, 2 = Hartford, 3 = Providence}
#'   \item{Tenure}{years with the firm}
#'   \item{Age}{age in years}
#'   \item{Practice}{1 = litigation, 2 = corporate}
#'   \item{LawSchool}{law school attended, as a code}
#' }
#' @source As [lazega].
#' @seealso [lazega]
#' @examples
#' table(lazega_attr$Office)
"lazega_attr"

#' Read's New Guinea highland tribes
#'
#' Alliance and opposition among 16 Gahuku-Gama sub-tribes in the central
#' highlands of New Guinea. Because it records positive and negative ties on the
#' same set of actors, it is the standard example for methods that handle signed
#' networks.
#'
#' @format An `xucinet` object, 16 x 16, two relations `Alliance` and
#'   `Opposition`, both binary and symmetric.
#' @source Read, K. (1954). Cultures of the central highlands, New Guinea.
#'   *Southwestern Journal of Anthropology*, 10, 1-43. See also Everett, M. G.
#'   and Borgatti, S. P. (2014). Networks containing negative ties. *Social
#'   Networks*, 38, 111-120.
#' @examples
#' xrelations(newguinea)
"newguinea"

#' Rehnquist court voting
#'
#' How the nine justices of the US Supreme Court voted on 376 cases between 1995
#' and 2004, the years of the second natural court under Chief Justice William
#' Rehnquist. A two-mode matrix of cases by judges.
#'
#' A cell is 1 where the judge voted with the majority on that case and 0 where
#' not. Thirty-two cells across eighteen cases hold 0.5, and nine cells are
#' missing; UCINET stores those as 1e38 and they arrive here as `NA`.
#'
#' @format An `xucinet` object, 376 cases x 9 judges, 2-mode.
#' @source Borgatti, S. P., Everett, M. G., Johnson, J. C. and Agneessens, F.
#'   *Analyzing Social Networks*. 3rd edition. Sage.
#' @seealso [supremecourt_cases_attr], [supremecourt_judges_attr]
#' @examples
#' dim(supremecourt)
#' sum(is.na(as.matrix(supremecourt)))
"supremecourt"

#' Supreme Court case attributes
#'
#' The row-mode attributes of [supremecourt]: one row per case.
#'
#' @format A data frame, 376 rows keyed by case id, 2 columns:
#' \describe{
#'   \item{Year}{year the case was decided}
#'   \item{Majority Size}{number of justices in the majority. The space is
#'     UCINET's own column label, so reach it with
#'     `supremecourt_cases_attr[["Majority Size"]]`.}
#' }
#' @source As [supremecourt].
#' @seealso [supremecourt], [supremecourt_judges_attr]
#' @examples
#' table(supremecourt_cases_attr$Year)
"supremecourt_cases_attr"

#' Supreme Court justice attributes
#'
#' The column-mode attributes of [supremecourt]: one row per justice.
#'
#' @format A data frame, 9 rows keyed by justice name, 11 columns:
#'   `NoTimesMajority`, the number of cases in which the justice was in the
#'   majority, then one column per year from `1995` to `2004` giving the same
#'   count within that year.
#' @source As [supremecourt].
#' @seealso [supremecourt], [supremecourt_cases_attr]
#' @examples
#' supremecourt_judges_attr[, "NoTimesMajority", drop = FALSE]
"supremecourt_judges_attr"
