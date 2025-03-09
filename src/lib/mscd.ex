defmodule Mscd do
  @moduledoc """
  Microsoft CD Player from Windows 2000

  It uses a query format similar to CDDB, sending track LBAs. We can use
  these to calculate a Musicbrainz disc ID and lookup the disc.
  """

  @doc """
  Given a disc query (see `Msdc.RequestParser`), use Musicbrainz to find
  matching releases and return the first one as a disc.
  """
  def lookup_disc(query, user) do
    {:ok, toc} = Mscd.RequestParser.parse_query(query)
    mb_disc_id = MusicBrainz.calculate_disc_id(toc.lead_out_lba, toc.track_lbas)
    {:ok, %{"releases" => releases}} = MusicBrainz.get_releases_by_disc_id(mb_disc_id)

    stat =
      user
      |> Map.put(:query, query)
      |> Map.put(:interface, "mscd")

    case releases do
      [] ->
        Cdigw.Stats.log_unsuccessful_query(stat)

        {:error, :not_found}

      # Only one disc is expected in the response
      [release | _] ->
        disc = MusicBrainz.release_to_disc(nil, release)

        stat
        |> Map.put(:title, disc.title)
        |> Map.put(:artist, disc.artist)
        |> Cdigw.Stats.log_successful_query()

        {:ok, disc}
    end
  end
end
