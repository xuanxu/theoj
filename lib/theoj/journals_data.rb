require "date"

module Theoj
  JOURNALS_DATA = {
    joss: {
      doi_prefix: "10.21105",
      url: "https://joss.theoj.org",
      name: "Journal of Open Source Software",
      alias: "joss",
      launch_date: "2016-05-05",
      papers_repository: "openjournals/joss-papers",
      reviews_repository: "openjournals/joss-reviews",
      deposit_url: "https://joss.theoj.org/papers/api_deposit"
    },
    jose: {
      doi_prefix: "10.21105",
      url: "https://jose.theoj.org",
      name: "Journal of Open Source Education",
      alias: "jose",
      launch_date: "2018-03-07",
      papers_repository: "openjournals/jose-papers",
      reviews_repository: "openjournals/jose-reviews",
      deposit_url: "https://jose.theoj.org/papers/api_deposit"
    },
    jcon: {
      doi_prefix: "10.21105",
      url: "https://proceedings.juliacon.org/",
      name: "The Proceedings of the JuliaCon Conferences",
      alias: "jcon",
      launch_date: "2019-07-21",
      papers_repository: "JuliaCon/proceedings-papers",
      reviews_repository: "JuliaCon/proceedings-review",
      deposit_url: "https://proceedings.juliacon.org/papers/api_deposit"
    },    
    resciencec: {
      doi_prefix: "10.21105",
      url: "https://resciencec.theoj.org",
      name: "ReScience C",
      alias: "resciencec",
      launch_date: "2015-05-23",
      papers_repository: "ReScience/ReScienceC-papers",
      reviews_repository: "ReScience/ReScienceC-reviews",
      deposit_url: "https://resciencec.theoj.org/papers/api_deposit"
    },
    test_journal: {
      doi_prefix: "10.21105",
      url: "https://test.joss.theoj.org/",
      name: "Test Journal",
      alias: "test_journal",
      launch_date: "2016-05-05",
      papers_repository: "openjournals/joss-papers-testing",
      reviews_repository: "openjournals/joss-reviews-testing",
      deposit_url: "https://test.joss.theoj.org/papers/api_deposit"
    }
  }
end
