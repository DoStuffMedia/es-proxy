require "json"
require "http/client"

class Elasticsearch

  JSON.mapping(
    term: String,
    metro_id: JSON::Any,
    from: JSON::Any,
    sort: JSON::Any
  )

  def clean_hit(hit)
    { attributes: hit["_source"], highlight: (hit.as_h.has_key?("highlight") ? hit["highlight"] : {} of String => String) }
  end

  def cleanse_hits(response)
    hits = Array(JSON::Any).new
    res = JSON.parse(response)
    res["hits"]["hits"].as_a.map {|h| clean_hit(h) }
  end

  def query
      q = {
        query: {
          bool: {
            must: [
              {
                bool: {
                  must: [
                    {
                      bool: {
                        should: [
                          {
                            multi_match: {
                              query: self.term,
                              fields: [
                                "email",
                                "full_name",
                                "display_name"
                              ],
                              type: "best_fields",
                              operator: "or",
                              fuzziness: 0
                            }
                          },
                          {
                            multi_match: {
                              query: self.term,
                              fields: [
                                "email",
                                "full_name",
                                "display_name"
                              ],
                              type: "phrase_prefix",
                              operator: "or"
                            }
                          },
                          {
                            term: {
                              metro_preferences_id: {
                                value: self.metro_id
                              }
                            }
                          }
                        ],
                        minimum_should_match: 1
                      }
                    }
                  ]
                }
              }
            ]
          }
        },
        highlight: {
          pre_tags: [
            "<mark>"
          ],
          post_tags: [
            "</mark>"
          ],
          fields: {
            full_name: {} of Symbol => String,
            display_name: {}  of Symbol => String,
            email: {}  of Symbol => String
          }
        },
        size: 7,
        _source: {
          includes: [
            "email",
            "name",
            "display_name"
          ]
        },
        from: self.from
      }
      response = HTTP::Client.post("http://localhost:9200/users_search_development_c6aca5fd38c19d66438457e5e/_search", headers: HTTP::Headers{"Content-Type" => "application/json"}, body: q.to_json)
      results = JSON.parse(response.body)
      {
        took: results["took"],
        from: self.from,
        hits: cleanse_hits(response.body)
      }
    end
end