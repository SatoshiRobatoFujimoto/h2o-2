package water.api;

import water.*;
import water.Weaver.Weave;

public class Progress2 extends Request {
  static final int API_WEAVER=1; // This file has auto-gen'd doc & json fields
  static public DocGen.FieldDoc[] DOC_FIELDS; // Initialized from Auto-Gen code.

  // This Request supports the HTML 'GET' command, and this is the help text
  // for GET.
  static final String DOC_GET = "Track progress of an ongoing Job";

  @Weave(help="The Job id being tracked.")
  final Str job = new Str("job");

  @Weave(help="The destination key being produced.")
  final Str dst_key = new Str("dst_key");

  public static Response redirect(Request req, Key jobkey, Key dest) {
    return new Response(Response.Status.redirect, req, -1, -1, "Progress2", "job", jobkey, "dst_key", dest );
  }

  @Override protected Response serve() {
    Job jjob = Job.findJob(Key.make(job.value()));
    return (jjob == null || jjob._endTime != 0 ) 
      ? jobDone      (jjob, dst_key.value())
      : jobInProgress(jjob, dst_key.value());
  }

  /** Return {@link Response} for finished job. */
  protected Response jobDone(final Job job, final String dst) {
    throw H2O.unimpl();
    //return Inspect.redirect(jsonResp, job, Key.make(_dest.value()));
  }

  /** Return default progress {@link Response}. */
  protected Response jobInProgress(final Job job, final String dst) {
    return new Response(Response.Status.poll, this, (int)(100*job.progress()), 100, null);
  }
  
  @Override public boolean toHTML( StringBuilder sb ) {
    Job jjob = Job.findJob(Key.make(job.value()));
    DocGen.HTML.title(sb,jjob._description);
    DocGen.HTML.section(sb,dst_key.value());
    return true;
  }

  @Override protected boolean log() { return false; }
}
